#include "rodos.h"
#include "hal/hal_gpio.h"

HAL_GPIO red(GPIO_062);

class Blinky : public StaticThread <> {

    public:
        Blinky() : StaticThread("Blinky", 100){ }

        void init(){
            red.init(1,1,0);
        }

        void run(){
            while(1){
                red.setPins(~red.readPins());
                AT(NOW() + 1*SECONDS);
            }
        }

} blinky;