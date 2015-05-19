program MapWindowsForm;

uses
  Forms,
  Unit1 in 'Unit1.pas' {ManWindowLaunchForm},
  Variants in 'Variants.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TManWindowLaunchForm, ManWindowLaunchForm);
  Application.Run;
end.
