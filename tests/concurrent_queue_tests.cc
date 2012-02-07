#include "gtest/gtest.h"

#include <string>

#include <boost/shared_ptr.hpp>
#include <boost/thread.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

// OMG this is so nasty...
#define private public
#define protected public

#include "serial/utils/concurrent_queue.h"
using namespace serial::utils;
using boost::posix_time::ptime;
using boost::posix_time::time_duration;
using boost::posix_time::microsec_clock;
using boost::posix_time::milliseconds;
using boost::thread;
using boost::bind;

namespace {

void my_sleep(long milliseconds) {
  boost::this_thread::sleep(boost::posix_time::milliseconds(milliseconds));
}

typedef boost::shared_ptr<std::string> TokenPtr;

class ConcurrentQueueTests : public ::testing::Test {
protected:
  virtual void SetUp() {
    
  }

  virtual void TearDown() {
    
  }

  void push_later(TokenPtr &token, long delay) {
    my_sleep(delay);
    queue.push(token);
  }

  ConcurrentQueue<TokenPtr> queue;

};

TEST_F(ConcurrentQueueTests, try_pop) {
  TokenPtr token_ptr;
  ASSERT_FALSE(queue.try_pop(token_ptr));
  ASSERT_TRUE(queue.empty());
  for(size_t i = 0; i < 10; ++i) {
    queue.push(TokenPtr(new std::string("Testing.")));
  }
  ASSERT_FALSE(queue.empty());
  ASSERT_TRUE(queue.try_pop(token_ptr));
}

TEST_F(ConcurrentQueueTests, timed_wait_and_pop) {
  TokenPtr token_ptr;
  ptime start = microsec_clock::local_time();
  ASSERT_FALSE(queue.timed_wait_and_pop(token_ptr, 100));
  time_duration diff(microsec_clock::local_time() - start);
  ASSERT_GE(diff.total_milliseconds(), 100);
  ASSERT_TRUE(queue.empty());
  
  queue.push(TokenPtr(new std::string("Testing.")));
  ASSERT_FALSE(queue.empty());
  start = microsec_clock::local_time();
  ASSERT_TRUE(queue.timed_wait_and_pop(token_ptr, 100));
  diff = microsec_clock::local_time() - start;
  ASSERT_LT(diff.total_milliseconds(), 100);
  
  thread t(bind(&ConcurrentQueueTests::push_later, this,
                TokenPtr(new std::string("Testing.")), 30));
  start = microsec_clock::local_time();
  ASSERT_TRUE(queue.timed_wait_and_pop(token_ptr, 100));
  diff = microsec_clock::local_time() - start;
  ASSERT_LT(diff.total_milliseconds(), 100);
  ASSERT_GE(diff.total_milliseconds(), 30);
  ASSERT_TRUE(t.timed_join(milliseconds(100)));
}

TEST_F(ConcurrentQueueTests, timed_pop_doesnt_block_push) {
  TokenPtr token_ptr;
  ptime start = microsec_clock::local_time();
  thread t(bind(&ConcurrentQueue<TokenPtr>::timed_wait_and_pop, &queue,
                token_ptr, 30));
  my_sleep(10);
  queue.push(TokenPtr(new std::string("Testing.")));
  time_duration diff(microsec_clock::local_time() - start);
  ASSERT_TRUE(t.timed_join(milliseconds(100)));
  ASSERT_LT(diff.total_milliseconds(), 30);
  ASSERT_TRUE(queue.empty());
}

}  // namespace

int main(int argc, char **argv) {
  try {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
  } catch (std::exception &e) {
    std::cerr << "Unhandled Exception: " << e.what() << std::endl;
  }
  return 1;
}
