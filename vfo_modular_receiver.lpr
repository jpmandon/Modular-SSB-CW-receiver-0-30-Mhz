program vfo_modular_receiver;
{$MODE OBJFPC}
{$H+}
{$MEMORY 16384,16384}
uses
  pico_gpio_c,
  pico_i2c_c,si5351_i2c,
  pico_timer_c,
  pico_c,
  CustomDisplay,ssd1306_i2c_c,CustomDisplayFrameBuffer1Bit,
  Fonts.BitstreamVeraSansMono8x16, display,
  sysutils, button;

const

  enable           = 1                     ;
  disable          = 0                     ;
var
  ecran1           : Tdisplay              ;
  frequency        : uint64=14000000       ;
  scanButton       : uint32=20             ;
  ButtonLeft       : TButton;
  ButtonRight      : TButton;
  ButtonCenter     : TButton;

  procedure init;
  begin
  // Buttons
  ButtonLeft:=TButton.create(TPicoPin.GP15);
  ButtonRight:=TButton.create(TPicoPin.GP6);
  ButtonCenter:=TButton.create(TPicoPin.GP14);
  // I2C
  i2c_init(i2c1Inst, 400000);
  gpio_init(TPicoPin.GP10_I2C1_SDA);
  gpio_init(TPicoPin.GP11_I2C1_SDL);
  gpio_set_function(TPicoPin.GP10_I2C1_SDA, TGPIO_Function.GPIO_FUNC_I2C);
  gpio_set_function(TPicoPin.GP11_I2C1_SDL, TGPIO_Function.GPIO_FUNC_I2C);
  gpio_pull_up(TPicoPin.GP10);
  gpio_pull_up(TPicoPin.GP11);
  // SI5351
  frequency:=3620000;
  si5351_init(SI5351_CRYSTAL_LOAD_8PF, 25000000);
  si5351_set_correction(1572);
  si5351_set_freq(frequency,SI5351_CLK0);
  si5351_drive_strength(SI5351_CLK0,SI5351_DRIVE_4MA);
  si5351_output_enable(SI5351_CLK0,enable);
  end;

procedure ecran_init;
begin
ecran1.init(i2c1inst,$3c,TPicoPin.None,ScreenSize128x64x1);
end;

var
    timeButton       : int64   ;
    timeDisplay      : int64   ;
    needUpdateScreen : boolean=false ;
begin
  init;
  ecran_init;
  timeDisplay:=time_us_64;
  timeButton:=time_us_64;
  ecran1.Frequency:=frequency;
  ecran1.displayMain;

  repeat
    // Button refresh
    if (time_us_64-timeButton)>20000 then
       begin
         ButtonCenter.update;
         ButtonRight.update;
         ButtonLeft.update;
         timeButton:=time_us_64;
       end;
    // Screen refresh
    if (time_us_64-timeDisplay)>40000 then
       begin
         if ButtonCenter.isPressed then
            begin
            ecran1.update(ButtonCenterPressed);
            needUpdateScreen:=true;
            end
         else
         if  ButtonCenter.isHeld then
            begin
            ecran1.update(ButtonConfigPressed);
            ButtonCenter.waitRelease;
            needUpdateScreen:=true;
            end
         else
         if ButtonRight.isPressed or ButtonRight.isHeld then
            begin
            ecran1.update(ButtonRightPressed);
            needUpdateScreen:=true;
            end
         else
         if ButtonLeft.isPressed or ButtonLeft.isHeld then
            begin
            ecran1.update(ButtonLeftPressed);
            needUpdateScreen:=true;
            end;
         timeDisplay:=time_us_64;
       end;
    // Local oscillator refresh
    if needUpdateScreen then
       begin
       si5351_set_freq(ecran1.Frequency,SI5351_CLK0);
       needUpdateScreen:=false;
       end;

  until 1=0;
end.
