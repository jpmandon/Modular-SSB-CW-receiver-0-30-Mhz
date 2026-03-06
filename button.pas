unit button;

{$mode ObjFPC}{$H+}

interface

uses
  pico_gpio_c,pico_timer_c;

const
  idle     = 0 ;
  decoding = 1 ;
  active   = 2 ;

type TButton = class
  protected
  fpressed       : boolean        ;
  fgpio          : TPinIdentifier ;
  flastPress     : int64          ;
  fstate         : byte           ;
  fHeldCount     : int32          ;
  flastHeldCount : int32          ;
  fPressedCount  : int32          ;
  ftimeout       : int16          ;

  function is_held:boolean;
  function is_Pressed:boolean;

  public
  procedure update;
  procedure waitRelease;
  constructor create(gpio:TPinIdentifier);

  property isPressed : boolean read is_Pressed;
  property isHeld : boolean read is_Held;
  end;

implementation

constructor TButton.create(gpio:TPinIdentifier);
begin
  gpio_init(gpio);
  gpio_set_function(gpio, TGPIO_Function.GPIO_FUNC_SIO);
  gpio_set_dir(gpio,TGPIO_Direction.GPIO_IN);
  gpio_pull_up(gpio);
  fgpio:=gpio;
  fstate:=idle;
  flastPress:=-1;
  ftimeout:=500;
end;

procedure TButton.update;
begin
  if fstate=idle then
     begin
     if not gpio_get(fgpio) then
        begin
        flastPress:=time_us_32;
        fstate:=decoding;
        end;
     end
  else if fstate=decoding then
     begin
     if gpio_get(fgpio) then
        begin
        inc(fpressedCount);
        fstate:=idle;
        end
        else
        if (time_us_32-flastPress)>=(ftimeout*1000) then
           begin
           if fLastHeldCount=fheldCount then inc(fheldCount);
           end;
     end
  else if fstate=active then
     if gpio_get(fgpio) then
        begin
        fheldCount:=0;
        flastHeldCount:=0;
        fstate:=idle;
        end;
end;

function TButton.is_Pressed:boolean;
var
  etat:boolean;
begin
 etat:=fpressedCount>0;
 fpressedCount:=0;
 is_Pressed:=etat;
end;

function TButton.is_Held:boolean;
begin
 if fHeldCount>fLastHeldCount then
    begin
    inc(fLastHeldCount);
    is_Held:=true;
    end;
end;

procedure TButton.waitRelease;
begin
 fstate:=active;
end;

end.

