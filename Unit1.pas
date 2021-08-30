unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VclTee.TeeGDIPlus,
  VCLTee.TeEngine, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart,
  VCLTee.Series, Math, VCLTee.TeeSurfa, Vcl.ComCtrls, VCLTee.TeeSurfaceTool,
  VCLTee.TeeTriSurface, VCLTee.TeeTools;

type
  TForm1 = class(TForm)
    CloseButton: TButton;
    LoadDataButton: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    GroupBox1: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    AutorunButton: TButton;
    Chart1: TChart;
    Edit4: TEdit;
    Edit5: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Series2: TLineSeries;
    Label7: TLabel;
    ClearButton: TButton;
    GroupBox2: TGroupBox;
    rectangular: TRadioButton;
    triangular: TRadioButton;
    hanning: TRadioButton;
    hamming: TRadioButton;
    Chart3: TChart;
    Chart4: TChart;
    Series3: TLineSeries;
    Series4: TBarSeries;
    Series5: TLineSeries;
    Label8: TLabel;
    Edit6: TEdit;
    Chart2: TChart;
    TeeGDIPlus2: TTeeGDIPlus;
    Series1: TTriSurfaceSeries;
    TeeGDIPlus1: TTeeGDIPlus;
    Chart6: TChart;
    Series6: TTriSurfaceSeries;
    ChartTool1: TRotateTool;
    procedure LoadDataButtonClick(Sender: TObject);
    procedure proses_stft;
    procedure dft;
    procedure CloseButtonClick(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure AutorunButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  jmldata, d_awal, d_akhir, fs  :integer;
  lebar_w, geser, jml_w         :integer;

  datadft, min, max :integer;
  mag_stft :array [0..10000,0..10000] of real;
  sinyalwindow, window  : array [-100000..100000] of real;
  freq_stft, time_stft, dft_re,
  dft_im, inputdft, sinyaldft, sinyalinput : array [0..1000000] of extended;

implementation

{$R *.dfm}

procedure TForm1.dft;
var
  i, j, k :integer;
begin
  datadft := max - min + 1;
  for i := 0 to jmldata-1 do
  begin
    dft_re[i] := 0;
    dft_im[i] := 0;
    for j := 0 to jmldata-1 do
    begin
      dft_re[i] := dft_re[i] + inputdft[j]*cos(2*pi*j*i/jmldata);
      dft_im[i] := dft_im[i] - inputdft[j]*sin(2*pi*j*i/jmldata);
    end;
    sinyaldft[i] := sqrt(sqr(dft_re[i]) + sqr(dft_im[i]))/jmldata;
    freq_stft[i] := i*fs/datadft;
  end;

  for i := 0 to round(jmldata/2) do
  begin
    Series4.AddXY(i*fs/jmldata,sinyaldft[i]);
  end;
end;

procedure TForm1.proses_stft;
var
  i, j  :integer;
begin
  lebar_w := strtoint(Edit4.Text);
  geser   := strtoint(Edit5.Text);
  jml_w   := round(jmldata/((lebar_w div 2)+geser))+1;
  Label7.Caption := 'Jumlah Window : ' + inttostr(jml_w);

  for i := 0 to jml_w-1 do
  begin
    min := i*((lebar_w div 2) + geser) - (lebar_w div 2);
    max := min + lebar_w;

    if min < 0 then
      min := 0;

    for j := 0 to jmldata-1 do
      window[j] := 0; // inisialisasi nilai 0 untuk proses window

    for j := min to max do
    begin
      if rectangular.Checked then //rectangular window
        window[j] := 1
      else if triangular.Checked then  //triangular window
        window[j] := 1 - abs((2*((lebar_w div 2) + geser)) - lebar_w + 1)/(lebar_w - 1)
      else if hanning.Checked then  //hanning window
        window[j] := 0.5 - (0.5*cos((2*pi*(j-i*((lebar_w div 2) + geser)))/lebar_w))
      else if hamming.Checked then   //hamming window
        window[j] := 0.54 - (0.46*cos((2*pi*(j-i*((lebar_w div 2) + geser)))/lebar_w));

      sinyalwindow[j] := sinyalinput[j]*window[j];
      inputdft[j-min] := sinyalwindow[j];

      Series3.AddXY(j,sinyalwindow[j]);
      Series5.AddXY(j,window[j]);
    end;

    dft;

    for j := 0 to round(fs/2) do
    begin
      mag_stft[i,j] := sinyaldft[j];
    end;
  end;

  for i := 0 to jml_w-1 do
  begin
    time_stft[i] := (((lebar_w div 2) + geser)*i + d_awal)/fs;
  end;

  for i := 0 to jml_w-1 do
  begin
    for j := 0 to round(fs/2) do
    begin
      Series1.AddXYZ(time_stft[i],mag_stft[i,j],freq_stft[j]);
      Series6.AddXYZ(time_stft[i],mag_stft[i,j],freq_stft[j]);
    end;
  end;
end;

procedure TForm1.LoadDataButtonClick(Sender: TObject);
var
  i : integer;
begin
  d_awal := strtoint(Edit2.Text);
  d_akhir:= strtoint(Edit3.Text);

  fs := 800;
  jmldata := d_akhir - d_awal;
  for i := d_awal to d_akhir-1 do
  begin
    if i < round((d_akhir-d_awal)/4) then
      sinyalinput[i-d_awal] := 4*sin(2*pi*10*i/fs)
    else if (i >= round((d_akhir-d_awal)/4)) and (i < round(2*(d_akhir-d_awal)/4)) then
      sinyalinput[i-d_awal] := 2*sin(2*pi*20*i/fs)
    else if (i >= round(2*(d_akhir-d_awal)/4)) and (i < round(3*(d_akhir-d_awal)/4)) then
      sinyalinput[i-d_awal] := 8*sin(2*pi*40*i/fs)
    else
      sinyalinput[i-d_awal] := 1;
  end;

  for i := d_awal to d_akhir-1 do
  begin
    Series2.AddXY(i/fs,sinyalinput[i]);
  end;

  Edit1.Text := inttostr(fs);
  Edit6.Text := inttostr(jmldata);
end;

procedure TForm1.AutorunButtonClick(Sender: TObject);
begin
  proses_stft;
end;

procedure TForm1.ClearButtonClick(Sender: TObject);
begin
  Series1.Clear; Series2.Clear; Series3.Clear;
  Series4.Clear; Series5.Clear; Series6.Clear;
  Label7.Caption := '';
  rectangular.Checked := false;
  triangular.Checked := false;
  hanning.Checked := false;
  hamming.Checked := false;
  Edit1.Clear; Edit6.Clear;
end;

procedure TForm1.CloseButtonClick(Sender: TObject);
begin
  Close;
end;
end.
