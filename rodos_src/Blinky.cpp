#include "rodos.h"
#include "hal/hal_gpio.h"


HAL_GPIO green(GPIO_060);
HAL_GPIO orange(GPIO_061);
HAL_GPIO red(GPIO_062);
HAL_GPIO blue(GPIO_063);

class Blinky : public StaticThread <> {

    public:
        Blinky() : StaticThread("Blinky", 100){ }

        void init(){
            green.init(1,1,0);
            orange.init(1,1,0);
            red.init(1,1,0);
            blue.init(1,1,0);
        }

        void run(){
            while(1){
                green.setPins(~green.readPins());
                orange.setPins(~orange.readPins());
                red.setPins(~red.readPins());
                blue.setPins(~blue.readPins());
                AT(NOW() + 1*SECONDS);
            }
        }

} blinky;