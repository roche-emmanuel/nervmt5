
#include <nerv/unit/Testing.mqh>


BEGIN_TEST_PACKAGE(sanity_ref_specs)

BEGIN_TEST_SUITE("Sanity checks")

#ifdef TEST_REFERENCE_DELETION
BEGIN_TEST_CASE("should keep references on pointers.")
  /* This test will generate a runtime error
  because the child object is used after deletion. */
  class my_child
  {
    public:
    int test() {
      return 1;
    }
  };

  class container
  {
  protected:
    my_child* obj;
  public:
    container(): obj(NULL) {};

    void setObject(my_child* o) {
      obj = o;
    }

    my_child* getObject() {
      return obj;
    }
  };

  container cont;

  {
    my_child child;
    cont.setObject(GetPointer(child));
  }
	
	int res = cont.getObject().test();
  REQUIRE_EQUAL(res,1);
END_TEST_CASE()
#endif

BEGIN_TEST_CASE("should keep references on pointers.")
  /* This test will generate a runtime error
  because the child object is used after deletion. */
  class my_child
  {
    public:
    virtual int test() {
      return 1;
    }
  };

  class my_child_b : public my_child
  {
    public:
    virtual int test() {
      return 2;
    }
  };

  class container
  {
  private:
    my_child* obj;

  public:
    container(): obj(NULL) {};

    void setObject(my_child* o) {
      obj = o;
    }

    int getResult() {
      return obj.test();
    }
  };

  class container_b : public container
  {
  private:
    my_child_b* obj;

  public:
    container_b(): obj(NULL) {};

    void setObjectB(my_child* o) {
      obj = o;
    }

    int getResult2() {
      return obj.test();
    }
  };

  container_b cont;

  my_child child;
  cont.setObject(GetPointer(child));
  my_child_b childb;
  cont.setObjectB(GetPointer(childb));
  
  REQUIRE_EQUAL(cont.getResult(),1);
  REQUIRE_EQUAL(cont.getResult2(),2);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
