#include "Pthreads.h"

/*
 *	How to call this from Ruby: verbatim code inside ``
 *		run Ruby extconf.rb # `./extconf.rb` or `ruby extconf.rb`
 *		run `make`
 *		run `make install`
 *	This will install the correct package for your operating system. Currently only tested on Mac OSX 10.10
 *
 *	From Ruby:
 *		require 'PThreads' (this name will possibly change, and I will likely write a bytecode interpreter so I can pass data as well as functions)
 *		include PThreads
 *			then run either:
 *				pthreads { puts "Hello from ruby!" }
 *				or
 *				PThreads.pthreads { puts "Hello from ruby!" }
 *
 *	Again, these names will probably change to something more suitable once I've decided what I want this to evolve into
 *
 */


// VALUE is the default type for the Ruby interpreter and can be any Ruby object (as far as I am aware)
// Defining a space for information and references about the module to be stored internally
VALUE PThreads = Qnil;

// Prototype for the initialization method - Required by Ruby
void Init_PThreads();

// Defines our method Prototype, all methods here must be prefaced with method_
// Prototype for pthread_test
VALUE method_pthread_test(VALUE self);
// Prototype for print_hello
VALUE method_print_hello(VALUE self);

// Gets the total available CPU count for spawning threads
int get_cpu_count()
{
    return (int)sysconf(_SC_NPROCESSORS_ONLN);
}

// Was going to run a block of ruby code in parallel until I learned about the GIL (Global Interpreter Lock).
// Looks like most things I want to do will have to be data driven instead of interpreted, but I wasn't even sure what I wanted to do was possible in the first place.
// Either way, this function is a pointer to a function that takes a struct pointer of arguments that are dereferenced in the function itself
void *run_block(void *arguments)
{
    long tid;
    struct arg_struct *args = (struct arg_struct *)arguments;
    tid = (long)args->threadid;
    printf("Hello World! It's me, thread #%ld!\n", tid);

    pthread_exit(NULL);
}

// The actual method that will be called and defined in our Ruby module
VALUE pthread_test(VALUE self) {

    clock_t begin, end;
    double time_spent;
    // starts clock timer
    begin = clock();

    // setup time information
    time_t rawtime;
    struct tm *timeinfo;

    time ( &rawtime );
    timeinfo = localtime ( &rawtime );
    printf ( "Current local time and date: %s", asctime (timeinfo) );

    // get number of available cores
    int num_threads = get_cpu_count();
    // set number of available cores
    pthread_t threads[num_threads];

    // place to store thread attributes
    pthread_attr_t attr;
    // set actual attributes to joinable
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

    // setup thread ids
    int rc;
    long t;
    void *status;

    // ruby VALUE that becomes our Ruby block
    VALUE p;

    if(rb_block_given_p())
    {
        p = rb_block_proc();
        printf("Block was provided.\n");
    }
    else
    {
        rb_raise(rb_eArgError, "a block is required");
        return Qnil;
    }
	// Acceptable to be outside if/else because we raise an error and return if there is no block given.
    rb_funcall(p, rb_intern("call"), 0);

    for(t = 0; t < num_threads; t++){
        printf("In main: creating thread %ld\n", t);

        // assemble thread arguments
        struct arg_struct thread_args;
        thread_args.threadid = t;

        // create threads and pass function pointer and pointer to arguments for the thread to execute
        rc = pthread_create(&threads[t], &attr, run_block, (void *)&thread_args);
        if (rc){
            printf("ERROR; return code from pthread_create() is %d\n", rc);
            exit(-1);
        }
    }

       // Free attribute and wait for the other threads to finish
       pthread_attr_destroy(&attr);
       for(t=0; t<num_threads; t++) {
          rc = pthread_join(threads[t], &status);
          if (rc) {
             printf("ERROR; return code from pthread_join() is %d\n", rc);
             exit(-1);
             } else {

              printf("Main: completed join with thread %ld having a status of %ld\n",t,(long)status);

          }
       }

    end = clock();
    time_spent = (double)(end - begin) / CLOCKS_PER_SEC;

    VALUE run_time = rb_float_new(time_spent);
    return run_time;
}

// The initialization method for this module. Defines the module and its methods for us to use in Ruby.
void Init_PThreads() {
    // Defines the PThreads module in ruby
    PThreads = rb_define_module("PThreads");
    //Defines the pthreads method in ruby
    rb_define_method(PThreads, "pthreads", pthread_test, 0);
}