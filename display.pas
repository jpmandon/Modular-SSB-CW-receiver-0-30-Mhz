unit display;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils,ssd1306_i2c_c,
  pico_i2c_c,pico_gpio_c,CustomDisplay,
  Fonts.BitstreamVeraSansMono8x16,pico_timer_c;

type

  TButtonPressed = (
  ButtonLeftPressed,
  ButtonRightPressed,
  ButtonCenterPressed,
  ButtonConfigPressed,
  None);

  TStep = (
  _1HZ,
  _10HZ,
  _100HZ,
  _1khz,
  _10khz,
  _100khz,
  _1mhz,
  _10mhz);

  TIFMode = (
  _DIRECT,
  _IFmore,
  _IFminus );

  TMenuMode = (
  _Mode,
  _Band,
  _Expert );

  TConfigMode = (
  _IF );

  TMode = (
  _CW,
  _USB,
  _LSB );

  TBand = (
  _80m,
  _40m,
  _20m,
  _15m,
  _10m,
  _6m );

type
  Tdisplay = object
  fssd1306        : TSSD1306_I2C    ;
  fobject         : TObject         ;
  fFreqSelected   : boolean         ;
  fStepSelected   : boolean         ;
  fCurrentDisplay : byte            ;
  ffrequency      : uint64          ;
  ffreqIF         : uint64          ;
  fstep           : Tstep           ;
  fmenumode       : TMenuMode       ;
  fconfigMode     : TConfigMode     ;
  fmode           : Tmode           ;
  fband           : TBand           ;
  public
  constructor init(var I2C : TI2C_Inst;const aDisplayAddress : byte;const aPinRST : TPinIdentifier;const aScreenInfo : TPhysicalScreenInfo);
  procedure displayMain;
  procedure displayMenu;
  function update(Button : TButtonPressed):integer;
  property FreqSelected:boolean read fFreqSelected write fFreqSelected ;
  property StepSelected:boolean read fStepSelected write fStepSelected ;
  property Frequency   :uint64  read ffrequency    write ffrequency    ;
  property currentDisplay : byte read fCurrentDisplay write fCurrentDisplay;
  end;

implementation

var
  stepValueStr    : array[0..7] of string=('1 hz','10 hz','100 hz','1 khz','10 khz','100 khz','1 Mhz','10 Mhz');
  stepValue       : array[0..7] of integer=(1,10,100,1000,10000,100000,1000000,10000000);
  IFModeStr       : array[0..2] of string=('DIRECT','IF+','IF-');
  menuModeStr     : array[0..2] of string=('Mode','Band','Expert');
  configModeStr   : array[0..0] of string=('IF');
  expertStr       : array[0..0] of string=('');
  modeStr         : array[0..2] of string=('CW','USB','LSB');
  bandStr         : array[0..9] of string=('80m','60m','40m','30m','20m','17m','15m','12m','10m','6m');

const
  mainDisplay  =0;
  menuDisplay  =1;
  configDisplay=2;

constructor Tdisplay.init(var I2C : TI2C_Inst;const aDisplayAddress : byte;const aPinRST : TPinIdentifier;const aScreenInfo : TPhysicalScreenInfo);
begin
i2c_init(i2c1inst, 100000);
fssd1306.initialize(i2c1inst,aDisplayAddress,aPinRST,ScreenSize128x64x1);
fssd1306.setFontInfo(BitstreamVeraSansMono8x16);
fssd1306.Rotation := TDisplayRotation.None;
fCurrentDisplay:=mainDisplay;
fFreqSelected:=true;
fStepSelected:=false;
ffreqIF:=0;
fstep:=_1khz;
fmenumode:=_Mode;
fmode:=_CW;
fband:=_80m;
fconfigMode:=_IF;
update(TButtonPressed.None);
end;

procedure Tdisplay.displayMain;
var
    freqStr     : string  ;
    XFreq       : byte    ;
begin
freqStr:=inttostr(ffrequency);
Xfreq  := (128-(length(freqStr)*8)) Div 2;
fssd1306.clearScreen;
fssd1306.drawText('Frequency',0,0);
fssd1306.drawText(freqStr+' hz',xfreq-8,24);
fssd1306.drawText('Step',0,45);
fssd1306.drawText(stepValueStr[ord(fstep)],40,45);
 if FreqSelected then
    fssd1306.drawFastHLine(0,16,72);
 if StepSelected then
    fssd1306.drawFastHLine(0,60,32);
 fssd1306.updateScreen;
end;

procedure Tdisplay.displayMenu;
begin
fssd1306.clearScreen;
fssd1306.drawText('Configuration',0,0);
fssd1306.drawText(menuModeStr[ord(fmenumode)],0,45);
case fmenumode of
          _Mode  :fssd1306.drawText(modeStr[ord(fmode)],128-(length(modeStr[ord(fmode)])*8),45);
          _Band  :fssd1306.drawText(bandStr[ord(fband)],128-(length(bandStr[ord(fband)])*8),45);
          _expert:
          end;
fssd1306.updateScreen;
end;

function Tdisplay.update(Button : TButtonPressed):integer;
var
  returnValue : integer ;

begin
returnValue:=0;
case fCurrentDisplay of
     mainDisplay   : begin
                          case Button of
                               ButtonCenterPressed :
                                               begin
                                                if FreqSelected then
                                                   begin
                                                   StepSelected:=true;
                                                   FreqSelected:=false;
                                                   end
                                                else if StepSelected then
                                                   begin
                                                   StepSelected:=false;
                                                   FreqSelected:=true;
                                                   end;
                                                displayMain;
                                               end;
                               ButtonConfigPressed :
                                               begin
                                               fCurrentDisplay:=MenuDisplay;
                                               returnValue:=-1;
                                               displayMenu;
                                               end;
                               ButtonLeftPressed :
                                               begin
                                               if FreqSelected then
                                                 begin
                                                 frequency:=frequency-stepValue[ord(fstep)];
                                                 returnValue:=-1;
                                                 end;
                                               if StepSelected then
                                                 begin
                                                 if fstep>low(TStep) then fstep:=pred(fstep);
                                                 returnValue:=-1;
                                                 end;
                                               displayMain;
                                               end;
                               ButtonRightPressed :
                                               begin
                                               if FreqSelected then
                                                 begin
                                                 frequency:=frequency+stepValue[ord(fstep)];
                                                 returnValue:=-1;
                                                 end;
                                               if StepSelected then
                                                 begin
                                                 if fstep<high(TStep) then fstep:=succ(fstep);
                                                 returnValue:=-1;
                                                 end;
                                               displayMain;
                                               end;

                               end;
                     end;
     MenuDisplay   : begin
                     case Button of
                               ButtonConfigPressed :
                                 begin
                                 fCurrentDisplay:=MainDisplay;
                                 returnValue:=-1;
                                 displayMain;
                                 end;
                               ButtonRightPressed :
                                 begin
                                 case fmenumode of
                                           _MODE: if fmode<high(fmode) then fmode:=succ(fmode);
                                           _BAND: if fband<high(fband) then fband:=succ(fband);
                                           _EXPERT:
                                           end;
                                 returnValue:=-1;
                                 displayMenu;
                                 end;
                               ButtonLeftPressed :
                                 begin
                                 case fmenumode of
                                           _MODE: if fmode>low(fmode) then fmode:=pred(fmode);
                                           _BAND: if fband>low(fband) then fband:=pred(fband);
                                           _EXPERT:
                                           end;
                                 returnValue:=-1;
                                 displayMenu;
                                 end;
                               ButtonCenterPressed :
                                 begin
                                 if fmenumode<high(fmenumode) then fmenumode:=succ(fmenumode)
                                 else fmenumode:=low(fmenumode);
                                 returnValue:=-1;
                                 displayMenu;
                                 end;
                          end;
                     end;
     configDisplay : begin
                     case Button of
                         None:
                           begin
                           fssd1306.clearScreen;
                           fssd1306.drawText('Expert',0,0);
                           fssd1306.drawText(ConfigModeStr[ord(fconfigmode)],0,45);
                           case fconfigmode of
                                     _IF  :fssd1306.drawText(inttostr(ffreqIF),128-(length(inttostr(ffreqIF))*8),45);
                                     end;
                           fssd1306.updateScreen;
                           busy_wait_us_32(50000);
                           end;
                         ButtonConfigPressed :
                           begin
                           fCurrentDisplay:=MainDisplay;
                           returnValue:=-1;
                           end;
                         ButtonRightPressed :
                           begin
                           case fconfigMode of
                               _IF: begin
                                    end;
                           end;
                           end;
                         ButtonLeftPressed :
                           begin
                           case fconfigMode of
                               _IF: begin
                                    end;
                           end;

                           end;

                     end;
                     end;
     end;
update:=returnValue;
end;

end.

