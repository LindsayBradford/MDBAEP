unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, OleCtrls, MapWinGIS_TLB;

type
  TManWindowLaunchForm = class(TForm)
    MapLaunchButton: TButton;
    Map1: TMap;
    procedure MapLaunchButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ManWindowLaunchForm: TManWindowLaunchForm;

implementation

{$R *.dfm}

procedure TManWindowLaunchForm.MapLaunchButtonClick(Sender: TObject);
var
  sf: MapWinGIS_TLB.Shapefile;

begin
  sf := CoShapefile.Create();
  sf.Open('c:\dev\data\dan.shp', nil);
  Map1.AddLayer(sf, true);
end;

end.
