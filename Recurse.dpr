program Recurse;

uses
  Forms,
  main; // main.pas

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TformRecurse, formRecurse);
  Application.Run;
end.
