program FindIP;

uses
  Vcl.Forms,
  Main in 'Main.pas' {FormIPFinder};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormIPFinder, FormIPFinder);
  Application.Run;
end.