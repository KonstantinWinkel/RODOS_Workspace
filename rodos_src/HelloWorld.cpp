#include "rodos.h"

class HelloWorldThread : public StaticThread<> {

    public:
        HelloWorldThread() : StaticThread("Hello World", 100){ }

        void init(){ }

        void run(){
            PRINTF("Hello World\n");
        }

} helloworldthread;