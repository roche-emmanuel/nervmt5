
#include <nerv/unit/Testing.mqh>
#include <nerv/network/ZMQContext.mqh>
#include <nerv/network/ZMQSocket.mqh>

BEGIN_TEST_PACKAGE(zmq_specs)

BEGIN_TEST_SUITE("ZMQContext class")

BEGIN_TEST_CASE("should be able to retrieve singleton")
	nvZMQContext* context = nvZMQContext::instance();
	ASSERT(context!=NULL);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to init/uninit")
	nvZMQContext* context = nvZMQContext::instance();
	context.init();
	context.init();
	context.uninit();
	context.uninit();
END_TEST_CASE()

END_TEST_SUITE()

BEGIN_TEST_SUITE("ZMQSocket class")

BEGIN_TEST_CASE("Should be able to create a new socket")
  // // Should throw an error if not initialized:
  // BEGIN_ASSERT_ERROR("ZMQ is not initialized.")
	 //  nvZMQSocket socket(ZMQ_PAIR);
  // END_ASSERT_ERROR();
  
  // // Now initialize properly:
  // nvZMQContext::instance().init();
  // {nvZMQSocket socket2(ZMQ_PAIR);}
  // nvZMQContext::instance().uninit();

  // Should in fact auto init the context if needed:
  nvZMQSocket socket2(ZMQ_PAIR);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to open/close a new socket")
  nvZMQContext::instance().init();
  {
	  nvZMQSocket socket(ZMQ_PAIR);
		socket.close();
		socket.open(ZMQ_PUB);
		socket.close();    	
  }
  nvZMQContext::instance().uninit();
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to connect a socket")
  // force complete uninit:
  nvZMQContext::instance().uninit();

  nvZMQSocket socket(ZMQ_PAIR);
  socket.connect("tcp://localhost:22222");
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to bind a socket")
  // force complete uninit:
  nvZMQContext::instance().uninit();

  nvZMQSocket socket(ZMQ_PAIR);
  socket.bind("tcp://*:22222");
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to send/receive with simple commands")
  // force complete uninit:
  nvZMQContext::instance().uninit();

  nvZMQSocket client(ZMQ_PUSH);
	client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  string msg1 = "Hello world!";
  char ch1[];
  StringToCharArray(msg1,ch1);
  client.simple_send(ch1);

  Sleep(10); // We add some sleep to ensure the underlying IO threads gets
  // the time to send the message.

  char ch[];
  server.simple_receive(ch,13);
  int len = ArraySize( ch );
  ASSERT_EQUAL(len,13);
  string msg2 = CharArrayToString(ch);
  ASSERT_EQUAL(msg1,msg2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to send/receive with a message")
  // force complete uninit:
  nvZMQContext::instance().uninit();

  nvZMQSocket client(ZMQ_PUSH);
  client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  string msg1 = "Hello world!";
  char ch1[];
  StringToCharArray(msg1,ch1);
  client.send(ch1);

  char ch[];
  while(server.receive(ch)==0)
  {
    logDEBUG("Waiting...");
    Sleep(5); // We add some sleep to ensure the underlying IO threads gets
    // the time to send the message.    
  };

  int len = ArraySize( ch );
  ASSERT_EQUAL(len,13);
  string msg2 = CharArrayToString(ch);
  ASSERT_EQUAL(msg1,msg2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to handle multiple messages")
  // force complete uninit:
  nvZMQContext::instance().uninit();

  nvZMQSocket client(ZMQ_PUSH);
  client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  SimpleRNG rng;
  rng.SetSeedFromSystemTime();

  int num = 30;
  int max_size = 1000;
  char data[];
  char data2[];
  for(int i =0;i<num;++i)
  {
    int size = rng.GetInt(10,max_size);
    ArrayResize( data, size );
    ArrayResize( data2, 0 );

    for(int j=0;j<size;++j)
    {
      data[j]=(char)rng.GetInt(0,255);
    }

    // Now send the data:
    client.send(data);

    while(server.receive(data2)==0)
    {
      logDEBUG("Waiting...");
      Sleep(5); // We add some sleep to ensure the underlying IO threads gets
      // the time to send the message.    
    };
   
    int size2 = ArraySize( data2 );
    ASSERT_EQUAL(size2,size);
    
    if(size2==size)
    {
      for(int j=0;j<size;++j)
      {
        ASSERT_EQUAL((int)data2[j],(int)data[j]);
      }
    }
  }
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to handle large messages")
  // force complete uninit:
  nvZMQContext::instance().uninit();

  nvZMQSocket client(ZMQ_PUSH);
  client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  SimpleRNG rng;
  rng.SetSeedFromSystemTime();

  int num = 2;
  int max_size = 20000;
  char data[];
  char data2[];
  for(int i =0;i<num;++i)
  {
    int size = max_size; //rng.GetInt(10,max_size);
    ArrayResize( data, size );
    ArrayResize( data2, 0 );

    for(int j=0;j<size;++j)
    {
      data[j]=(char)rng.GetInt(0,255);
    }

    // Now send the data:
    client.send(data);

    while(server.receive(data2)==0)
    {
      logDEBUG("Waiting...");
      Sleep(5); // We add some sleep to ensure the underlying IO threads gets
      // the time to send the message.    
    };

    ASSERT_EQUAL(ArraySize( data2 ),size);

    for(int j=0;j<size;++j)
    {
      ASSERT_EQUAL((int)data2[j],(int)data[j]);
    }
  }
END_TEST_CASE()

BEGIN_TEST_CASE("Should return nothing if there is no data to receive")
  nvZMQContext::instance().uninit();

  nvZMQSocket client(ZMQ_PUSH);
  client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  char data[];

  server.receive(data);
  ASSERT_EQUAL(ArraySize( data ),0);  
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to set Linger option on a socket")
  nvZMQContext::instance().uninit();
  nvZMQSocket socket(ZMQ_PUSH);

  socket.connect("tcp://localhost:22221");  

  char ch1[];
  StringToCharArray("Hello world!",ch1);

  socket.send(ch1);
  Sleep(5);

  // Now close the socket and stop:
  socket.close();
  nvZMQContext::instance().uninit();  
END_TEST_CASE()


XBEGIN_TEST_CASE("Should be able to send data to lua")
  nvZMQContext::instance().uninit();

  nvZMQSocket client(ZMQ_PUSH);
  client.connect("tcp://localhost:22223");  

  char ch[];
  StringToCharArray("Hello Manu! It's me!\nHow have you bean ?\n",ch);
  client.send(ch);
  Sleep( 5 );

  client.close();

  nvZMQSocket client2(ZMQ_PUSH);
  client2.connect("tcp://localhost:22223");  

  StringToCharArray("You are too strong!\n",ch);
  client2.send(ch);

  Sleep( 5 );
  client2.close();
  
  nvZMQContext::instance().uninit();
END_TEST_CASE()

BEGIN_TEST_CASE("Should convert properly int32 to structure")
  int val[] = {1};
  int32_stream opt;
  ArrayFill(opt.data,0,4,0);  

  long lval[] = {2};
  long src2 = getMemAddress(lval);
  logDEBUG("Read long address: "<<src2);

  long src = getMemAddress(val);
  logDEBUG("Read int address: "<<src);
  long dest = getMemAddress(opt.data);

  memcpy(dest,src,4);
  // data is written in little endian :-)
  ASSERT_EQUAL((int)opt.data[0],1);
  ASSERT_EQUAL((int)opt.data[1],0);
  ASSERT_EQUAL((int)opt.data[2],0);
  ASSERT_EQUAL((int)opt.data[3],0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
