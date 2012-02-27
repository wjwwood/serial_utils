#ifndef CONCURRENT_QUEUE_H
#define CONCURRENT_QUEUE_H

#include <queue>
#include <boost/thread.hpp>

namespace serial {
  namespace utils {
// Based on: http://www.justsoftwaresolutions.co.uk/threading/implementing-a-thread-safe-queue-using-condition-variables.html
template<typename Data>
class ConcurrentQueue
{
private:
  std::queue<Data> the_queue;
  mutable boost::mutex the_mutex;
  boost::condition_variable the_condition_variable;
  bool canceled_;
public:
  ConcurrentQueue() : canceled_(false) {}

  void push(Data const& data) {
    boost::mutex::scoped_lock lock(the_mutex);
    the_queue.push(data);
    lock.unlock();
    the_condition_variable.notify_one();
  }

  bool empty() const {
    boost::mutex::scoped_lock lock(the_mutex);
    return the_queue.empty();
  }

  bool try_pop(Data& popped_value) {
    boost::mutex::scoped_lock lock(the_mutex);
    if(the_queue.empty()) {
      return false;
    }

    popped_value=the_queue.front();
    the_queue.pop();
    return true;
  }

  bool timed_wait_and_pop(Data& popped_value, long timeout) {
    using namespace boost::posix_time;
    bool result;
    boost::mutex::scoped_lock lock(the_mutex);
    result = !the_queue.empty();
    if (!result) {
      result = the_condition_variable.timed_wait(lock, milliseconds(timeout));
    }

    if (result) {
      popped_value = the_queue.front();
      the_queue.pop();
    }
    return result;
  }

  void wait_and_pop(Data& popped_value) {
    boost::mutex::scoped_lock lock(the_mutex);
    while(the_queue.empty() && !this->canceled_) {
      the_condition_variable.wait(lock);
    }

    if (!this->canceled_) {
      popped_value = the_queue.front();
      the_queue.pop();
    }
  }

  size_t size() const {
    return the_queue.size();
  }

  void cancel() {
    this->canceled_ = true;
    the_condition_variable.notify_all();
  }

  void clear_cancel() {
    this->canceled_ = false;
  }

  void clear() {
    boost::mutex::scoped_lock lock(the_mutex);
    while (!the_queue.empty()) {
      the_queue.pop();
    }
  }
};
  }
}

#endif // CONCURRENT_QUEUE_H
