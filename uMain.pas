unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Effects,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.IOUtils, FMX.Menus,
  System.StrUtils,
  System.DateUtils,
  uStatistics;

type
  TGameMode = (gmNone, gmPlayerVsPlayer, gmPlayerXVsComputer, gmPlayerOVsComputer);

  TfrmMain = class(TForm)
    GridGame: TGridLayout;
    Tile1: TRectangle;
    Tile2: TRectangle;
    Tile3: TRectangle;
    Tile4: TRectangle;
    Tile5: TRectangle;
    Tile6: TRectangle;
    Tile7: TRectangle;
    Tile8: TRectangle;
    Tile9: TRectangle;
    TileO1: TImage;
    TileX1: TImage;
    TileO2: TImage;
    TileX2: TImage;
    TileO3: TImage;
    TileX3: TImage;
    TileO4: TImage;
    TileX4: TImage;
    TileO5: TImage;
    TileX5: TImage;
    TileO6: TImage;
    TileX6: TImage;
    TileO7: TImage;
    TileX7: TImage;
    TileO8: TImage;
    TileX8: TImage;
    TileO9: TImage;
    TileX9: TImage;
    layHeader: TLayout;
    layHeaderTitle: TLayout;
    imgWinnerO: TImage;
    imgWinnerX: TImage;
    lblHeaderTitle: TLabel;
    layWinnerOverlay: TLayout;
    layMenu: TRectangle;
    btnPlayerVsPlayer: TRectangle;
    Label1: TLabel;
    btnPlayerOVsComputer: TRectangle;
    Label2: TLabel;
    btnPlayerXVsComputer: TRectangle;
    Label3: TLabel;
    btnMatchHistory: TRectangle;
    Label4: TLabel;
    btnExit: TRectangle;
    Label5: TLabel;
    btnOptions: TRectangle;
    Label6: TLabel;
    btnAchievements: TRectangle;
    Label7: TLabel;
    layMatchHistory: TLayout;
    layMatchHistoryInner: TRectangle;
    Label8: TLabel;
    layOptions: TLayout;
    Rectangle2: TRectangle;
    Label9: TLabel;
    btnGoHomeFromOptions: TRectangle;
    Label10: TLabel;
    btnGoHomeFromMatchHistory: TRectangle;
    Label11: TLabel;
    layAchievements: TLayout;
    layAchievementsInner: TRectangle;
    btnGoHomeFromAchievements: TRectangle;
    Label13: TLabel;
    memMatchHistory: TMemo;
    layHome: TLayout;
    Label14: TLabel;
    Label15: TLabel;
    DebugMenu: TMenuBar;
    DebugMenuOptions: TMenuItem;
    DebugMenuFullScreen: TMenuItem;
    DebugMenuFile: TMenuItem;
    DebugMenuExit: TMenuItem;
    DebugMenuHelp: TMenuItem;
    DebugMenuAbout: TMenuItem;
    btnStatistics: TRectangle;
    Label16: TLabel;
    layStatistics: TLayout;
    Rectangle1: TRectangle;
    Label17: TLabel;
    btnGoHomeFromStatistics: TRectangle;
    Label18: TLabel;
    memStatistics: TMemo;
    layGame: TLayout;
    lblGameTimer: TLabel;
    layContainer: TLayout;
    VertScrollBox1: TVertScrollBox;
    Achievement_1: TRectangle;
    Image1: TImage;
    Layout1: TLayout;
    Label12: TLabel;
    Label19: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure TileClick(Sender: TObject);
    procedure layWinnerOverlayClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure ButtonMouseEnter(Sender: TObject);
    procedure ButtonMouseLeave(Sender: TObject);
    procedure btnPlayerVsPlayerClick(Sender: TObject);
    procedure btnPlayerXVsComputerClick(Sender: TObject);
    procedure btnPlayerOVsComputerClick(Sender: TObject);
    procedure btnMatchHistoryClick(Sender: TObject);
    procedure btnAchievementsClick(Sender: TObject);
    procedure btnGoHomeClick(Sender: TObject);
    procedure btnOptionsClick(Sender: TObject);
    procedure DebugMenuFullScreenClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnStatisticsClick(Sender: TObject);
  private
    { Private declarations }
    FTiles: array[1..9] of TRectangle;
    FTileX: array[1..9] of TImage;
    FTileO: array[1..9] of TImage;
    FBoard: array[1..9] of Char;
    FMode: TGameMode;
    FCurrentTurn: Char;
    FGameOver: Boolean;

    FStats: TGameStatistics;
    FTimerThread: TThread;
    FTimerActive: Boolean;
    FMatchStartTime: TDateTime;

    procedure InitTileArrays;
    procedure SetHeaderNormal;
    procedure StartMatch(Mode: TGameMode);
    procedure ClearBoard;
    function BoardWinner: Char;
    function IsEmptyCell(Index: Integer): Boolean;
    procedure PlaceMark(Index: Integer; Mark: Char);
    function IsPlayersTurn: Boolean;
    function PlayerMark: Char;
    function ComputerMark: Char;
    procedure ComputerMove;
    procedure FinishMatch(Winner: Char);
    procedure ResetGame();
    procedure DeclareWinner(Winner, Who: Char);
    procedure LoadMatchHistoryFromFile;
    procedure SaveMatchHistoryToFile;
    function MatchHistoryFilePath: string;
    function StatisticsFilePath: string;
    function StatsMode: TStatisticsMode;
    procedure UpdateStatisticsMemo;
    procedure StartTimer;
    procedure StopTimer(UpdateFinal: Boolean = True);
    procedure SelectLayout(Lay: TLayout = nil);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.SelectLayout(Lay: TLayout);
  procedure HideAll;
  begin
    for var I := 0 to layContainer.ChildrenCount - 1 do
      if layContainer.Children[I] is TLayout then
        TLayout(layContainer.Children[I]).Visible := False;
  end;
begin
  HideAll;
  if Assigned(Lay) then
    Lay.Visible := True;
end;

function TfrmMain.StatisticsFilePath: string;
begin
  var ExeName := TPath.GetFileNameWithoutExtension(ParamStr(0));
  if ExeName = '' then
    ExeName := 'TuxTacToe';
  Result := TPath.Combine(TPath.GetDocumentsPath, ExeName + '_Statistics.ini');
end;

function TfrmMain.StatsMode: TStatisticsMode;
begin
  if FMode = gmPlayerVsPlayer then
    Exit(smPvP);
  Exit(smVsComputer);
end;

procedure TfrmMain.UpdateStatisticsMemo;
begin
  if (memStatistics = nil) or (FStats = nil) then
    Exit;
  FStats.BuildStatisticsLines(memStatistics.Lines);
end;

procedure TfrmMain.StartTimer;
begin
  StopTimer(False);
  FMatchStartTime := Now;
  FTimerActive := True;
  FTimerThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while FTimerActive do
      begin
        var MS := MilliSecondsBetween(Now, FMatchStartTime);
        var Text := '';
        if MS < 60000 then
        begin
          // show seconds with milliseconds: S.mmm
          var S := MS div 1000;
          var R := MS mod 1000;
          Text := 'Time: ' + IntToStr(S) + '.' + IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R)) + 's';
        end
        else if MS < 3600000 then
        begin
          var TotalSec := MS div 1000;
          var M := TotalSec div 60;
          var S := TotalSec mod 60;
          var R := MS mod 1000;
          Text := Format('Time: %d:%s.%s', [M, IfThen(S < 10, '0' + IntToStr(S), IntToStr(S)), IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R))]);
        end
        else if MS < 86400000 then
        begin
          var TotalSec := MS div 1000;
          var H := TotalSec div 3600;
          var M := (TotalSec mod 3600) div 60;
          var S := TotalSec mod 60;
          var R := MS mod 1000;
          Text := Format('Time: %d:%s:%s.%s', [H, IfThen(M < 10, '0' + IntToStr(M), IntToStr(M)), IfThen(S < 10, '0' + IntToStr(S), IntToStr(S)), IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R))]);
        end
        else
        begin
          var D := MS div 86400000;
          var Rms := MS mod 86400000;
          var H := Rms div 3600000;
          var M := (Rms mod 3600000) div 60000;
          var S := (Rms mod 60000) div 1000;
          var R := Rms mod 1000;
          Text := Format('Time: %dd %d:%s:%s.%s', [D, H, IfThen(M < 10, '0' + IntToStr(M), IntToStr(M)), IfThen(S < 10, '0' + IntToStr(S), IntToStr(S)), IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R))]);
        end;

        TThread.Queue(nil,
          procedure
          begin
            if Assigned(lblGameTimer) then
              lblGameTimer.Text := Text;
          end);

        Sleep(100);
      end;
    end);
  FTimerThread.FreeOnTerminate := True;
  FTimerThread.Start;
end;

procedure TfrmMain.StopTimer(UpdateFinal: Boolean = True);
begin
  if not FTimerActive then
    Exit;
  FTimerActive := False;
  // let thread exit (it is FreeOnTerminate)
  if UpdateFinal and Assigned(lblGameTimer) then
  begin
    var MS := MilliSecondsBetween(Now, FMatchStartTime);
    var Text := '';
    if MS < 60000 then
    begin
      var S := MS div 1000;
      var R := MS mod 1000;
      Text := 'Time: ' + IntToStr(S) + '.' + IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R)) + 's';
    end
    else if MS < 3600000 then
    begin
      var TotalSec := MS div 1000;
      var M := TotalSec div 60;
      var S := TotalSec mod 60;
      var R := MS mod 1000;
      Text := Format('Time: %d:%s.%s', [M, IfThen(S < 10, '0' + IntToStr(S), IntToStr(S)), IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R))]);
    end
    else if MS < 86400000 then
    begin
      var TotalSec := MS div 1000;
      var H := TotalSec div 3600;
      var M := (TotalSec mod 3600) div 60;
      var S := TotalSec mod 60;
      var R := MS mod 1000;
      Text := Format('Time: %d:%s:%s.%s', [H, IfThen(M < 10, '0' + IntToStr(M), IntToStr(M)), IfThen(S < 10, '0' + IntToStr(S), IntToStr(S)), IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R))]);
    end
    else
    begin
      var D := MS div 86400000;
      var Rms := MS mod 86400000;
      var H := Rms div 3600000;
      var M := (Rms mod 3600000) div 60000;
      var S := (Rms mod 60000) div 1000;
      var R := Rms mod 1000;
      Text := Format('Time: %dd %d:%s:%s.%s', [D, H, IfThen(M < 10, '0' + IntToStr(M), IntToStr(M)), IfThen(S < 10, '0' + IntToStr(S), IntToStr(S)), IfThen(R < 100, IfThen(R < 10, '00' + IntToStr(R), '0' + IntToStr(R)), IntToStr(R))]);
    end;
    lblGameTimer.Text := Text;
  end;
  FTimerThread := nil;
end;

procedure TfrmMain.layWinnerOverlayClick(Sender: TObject);
begin
  FMode := gmNone;
  SetHeaderNormal;
  SelectLayout(layHome);
end;

procedure TfrmMain.InitTileArrays;
begin
  FTiles[1] := Tile1;
  FTiles[2] := Tile2;
  FTiles[3] := Tile3;
  FTiles[4] := Tile4;
  FTiles[5] := Tile5;
  FTiles[6] := Tile6;
  FTiles[7] := Tile7;
  FTiles[8] := Tile8;
  FTiles[9] := Tile9;

  FTileX[1] := TileX1;
  FTileX[2] := TileX2;
  FTileX[3] := TileX3;
  FTileX[4] := TileX4;
  FTileX[5] := TileX5;
  FTileX[6] := TileX6;
  FTileX[7] := TileX7;
  FTileX[8] := TileX8;
  FTileX[9] := TileX9;

  FTileO[1] := TileO1;
  FTileO[2] := TileO2;
  FTileO[3] := TileO3;
  FTileO[4] := TileO4;
  FTileO[5] := TileO5;
  FTileO[6] := TileO6;
  FTileO[7] := TileO7;
  FTileO[8] := TileO8;
  FTileO[9] := TileO9;
end;

procedure TfrmMain.SetHeaderNormal;
begin
  lblHeaderTitle.Text := 'Tic Tux Toe!';
  layHeaderTitle.Width := 597;
  imgWinnerO.Visible := True;
  imgWinnerX.Visible := True;
end;
procedure TfrmMain.StartMatch(Mode: TGameMode);
begin
  ResetGame;
  FMode := Mode;
  FGameOver := False;
  layWinnerOverlay.Visible := False;
  layHome.Visible := False;
  SetHeaderNormal;

  // ensure game layout is visible when a match starts
  SelectLayout(layGame);

  if FStats <> nil then
    FStats.RecordMatchStarted(StatsMode);
  StartTimer;

  case FMode of
    gmPlayerVsPlayer: FCurrentTurn := 'X';
    gmPlayerXVsComputer: FCurrentTurn := 'X';
    gmPlayerOVsComputer: FCurrentTurn := 'X'; // computer starts as X
  else
    FCurrentTurn := 'X';
  end;

  if (FMode = gmPlayerOVsComputer) then
    ComputerMove;
end;

procedure TfrmMain.ClearBoard;
begin
  for var I := 1 to 9 do
    FBoard[I] := ' ';
end;

function TfrmMain.IsEmptyCell(Index: Integer): Boolean;
begin
  Result := (Index >= 1) and (Index <= 9) and (FBoard[Index] = ' ');
end;

procedure TfrmMain.PlaceMark(Index: Integer; Mark: Char);
begin
  if not IsEmptyCell(Index) then
    Exit;

  FBoard[Index] := Mark;

  if Mark = 'X' then
  begin
    FTileX[Index].Visible := True;
    FTileO[Index].Visible := False;
  end
  else if Mark = 'O' then
  begin
    FTileO[Index].Visible := True;
    FTileX[Index].Visible := False;
  end;
end;

function TfrmMain.BoardWinner: Char;
  function LineWinner(A, B, C: Integer): Char;
  begin
    Result := #0;
    if (FBoard[A] <> ' ') and (FBoard[A] = FBoard[B]) and (FBoard[B] = FBoard[C]) then
      Result := FBoard[A];
  end;
begin
  Result := LineWinner(1, 2, 3);
  if Result <> #0 then Exit;
  Result := LineWinner(4, 5, 6);
  if Result <> #0 then Exit;
  Result := LineWinner(7, 8, 9);
  if Result <> #0 then Exit;
  Result := LineWinner(1, 4, 7);
  if Result <> #0 then Exit;
  Result := LineWinner(2, 5, 8);
  if Result <> #0 then Exit;
  Result := LineWinner(3, 6, 9);
  if Result <> #0 then Exit;
  Result := LineWinner(1, 5, 9);
  if Result <> #0 then Exit;
  Result := LineWinner(3, 5, 7);
  if Result <> #0 then Exit;

  for var I := 1 to 9 do
    if FBoard[I] = ' ' then
      Exit(#0);

  Exit('=');
end;

function TfrmMain.PlayerMark: Char;
begin
  case FMode of
    gmPlayerOVsComputer: Result := 'O';
    gmPlayerXVsComputer: Result := 'X';
  else
    Result := 'X';
  end;
end;

function TfrmMain.ComputerMark: Char;
begin
  case FMode of
    gmPlayerOVsComputer: Result := 'X';
    gmPlayerXVsComputer: Result := 'O';
  else
    Result := ' ';
  end;
end;

function TfrmMain.IsPlayersTurn: Boolean;
begin
  case FMode of
    gmPlayerVsPlayer: Result := True;
    gmPlayerXVsComputer, gmPlayerOVsComputer: Result := (FCurrentTurn = PlayerMark);
  else
    Result := False;
  end;
end;

procedure TfrmMain.ComputerMove;
begin
  if FGameOver then Exit;
  if not (FMode in [gmPlayerXVsComputer, gmPlayerOVsComputer]) then Exit;
  if (FCurrentTurn <> ComputerMark) then Exit;

  var Choices: TArray<Integer>;
  SetLength(Choices, 0);
  for var I := 1 to 9 do
  begin
    if IsEmptyCell(I) then
    begin
      SetLength(Choices, Length(Choices) + 1);
      Choices[High(Choices)] := I;
    end;
  end;

  if Length(Choices) = 0 then Exit;

  var Pick := Choices[Random(Length(Choices))];
  PlaceMark(Pick, ComputerMark);
  if FStats <> nil then
    FStats.RecordMove(Pick, ComputerMark, True);

  var Winner := BoardWinner;
  if Winner <> #0 then
  begin
    FinishMatch(Winner);
    Exit;
  end;

  FCurrentTurn := PlayerMark;
end;

procedure TfrmMain.FinishMatch(Winner: Char);
begin
  FGameOver := True;

  var Who: Char := 'P';
  if CharInSet(Winner, ['X', 'O']) and (FMode in [gmPlayerXVsComputer, gmPlayerOVsComputer]) then
    if Winner = ComputerMark then
      Who := 'C';

  if FStats <> nil then
    FStats.RecordMatchFinished(Winner, Who, StatsMode);
  DeclareWinner(Winner, Who);
  UpdateStatisticsMemo;
  StopTimer(True);
end;

procedure TfrmMain.ResetGame();
begin
  if (FMode <> gmNone) and (not FGameOver) and (FStats <> nil) then
    FStats.RecordMatchAbandoned;
  StopTimer(False);
  // hide all layouts
  SelectLayout(nil);
  ClearBoard;
  FGameOver := False;
  TileO1.Visible := False;
  TileX1.Visible := False;
  TileO2.Visible := False;
  TileX2.Visible := False;
  TileO3.Visible := False;
  TileX3.Visible := False;
  TileO4.Visible := False;
  TileX4.Visible := False;
  TileO5.Visible := False;
  TileX5.Visible := False;
  TileO6.Visible := False;
  TileX6.Visible := False;
  TileO7.Visible := False;
  TileX7.Visible := False;
  TileO8.Visible := False;
  TileX8.Visible := False;
  TileO9.Visible := False;
  TileX9.Visible := False;
  layWinnerOverlay.Visible := False;
  SetHeaderNormal;
  if Assigned(lblGameTimer) then
    lblGameTimer.Text := 'Time: 0.000s';
end;

procedure TfrmMain.btnAchievementsClick(Sender: TObject);
begin
  SelectLayout(layAchievements);
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.btnGoHomeClick(Sender: TObject);
begin
  ResetGame;
  FMode := gmNone;
  SelectLayout(layHome);
  SetHeaderNormal;
end;

procedure TfrmMain.btnMatchHistoryClick(Sender: TObject);
begin
  SelectLayout(layMatchHistory);
end;

procedure TfrmMain.btnOptionsClick(Sender: TObject);
begin
  SelectLayout(layOptions);
end;

procedure TfrmMain.btnPlayerOVsComputerClick(Sender: TObject);
begin
  StartMatch(gmPlayerOVsComputer);
end;

procedure TfrmMain.btnPlayerVsPlayerClick(Sender: TObject);
begin
  StartMatch(gmPlayerVsPlayer);
end;

procedure TfrmMain.btnPlayerXVsComputerClick(Sender: TObject);
begin
  StartMatch(gmPlayerXVsComputer);
end;

procedure TfrmMain.btnStatisticsClick(Sender: TObject);
begin
  SelectLayout(layStatistics);
  UpdateStatisticsMemo;
end;

procedure TfrmMain.ButtonMouseEnter(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := $FF39AEDE;
end;

procedure TfrmMain.ButtonMouseLeave(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := $FFE0E0E0;
end;

procedure TfrmMain.DebugMenuFullScreenClick(Sender: TObject);
begin
//  frmMain.FullScreen := not(frmMain.FullScreen);
//  TMenuItem(Sender).IsChecked := frmMain.FullScreen;
end;

procedure TfrmMain.DeclareWinner(Winner, Who: Char);
begin
  layWinnerOverlay.Visible := True;
  imgWinnerO.Visible := (Winner = 'O') OR (Winner = '=') OR (Winner = ' ');
  imgWinnerX.Visible := (Winner = 'X') OR (Winner = '=') OR (Winner = ' ');

  case Winner of
    ' ': begin
      lblHeaderTitle.Text := 'Tic Tux Toe!';
      layHeaderTitle.Width := 597;
    end;
    '=': begin
      lblHeaderTitle.Text := 'Draw!';
      layHeaderTitle.Width := 387;
    end;
    else begin
      lblHeaderTitle.Text := 'Winner!';
      layHeaderTitle.Width := 387;
    end;
  end;

  if (Winner <> ' ') then
  begin
    var WhoText := 'Computer';
    if (Who = 'P') then WhoText := 'Player';
    var ResultText: String;
    case Winner of
      'X': ResultText := WhoText + ' (X) wins!';
      'O': ResultText := WhoText + ' (O) wins!';
      '=': ResultText := 'Match ended in a draw.';
    end;
      memMatchHistory.Lines.Insert(0, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + ResultText);
      SaveMatchHistoryToFile;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  {$IFDEF RELEASE}
    DebugMenu.Visible := False;
  {$ENDIF}
  Randomize;
  InitTileArrays;

  FStats := TGameStatistics.Create(StatisticsFilePath);
  FStats.Load;
  FStats.StartNewSession;

  // Inline ShowHome behavior
  ResetGame;
  FMode := gmNone;
  SelectLayout(layHome);
  SetHeaderNormal;
  LoadMatchHistoryFromFile;
  UpdateStatisticsMemo;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  if (frmMain.Height < 880) then
  begin
    layMenu.Height := 619; // Minimum height that this component can be.
    layHeader.Margins.Top := 0; // Default
    btnMatchHistory.Margins.Top := 10; // Default
  end else
  begin
    layHeader.Margins.Top := 25;
    if (frmMain.Height > 995) then
    begin
      layMenu.Height := 770;
      btnMatchHistory.Margins.Top := 85;
    end else
    begin
      layMenu.Height := 696;
      btnMatchHistory.Margins.Top := 10; // Default
    end;
  end;
end;

procedure TfrmMain.TileClick(Sender: TObject);
begin
  var ClickedTileName := String(TRectangle(Sender).Name);
  var ClickedTileNumber := ClickedTileName.Replace('Tile','').ToInteger;

  if layWinnerOverlay.Visible then
  begin
    Exit;
  end;
  if FGameOver then
  begin
    Exit;
  end;
  if FMode = gmNone then
  begin
    Exit;
  end;
  if (ClickedTileNumber < 1) or (ClickedTileNumber > 9) then
  begin
    Exit;
  end;
  if not IsPlayersTurn then
  begin
    Exit;
  end;
  if not IsEmptyCell(ClickedTileNumber) then
  begin
    Exit;
  end;

  PlaceMark(ClickedTileNumber, FCurrentTurn);
  if FStats <> nil then
    FStats.RecordMove(ClickedTileNumber, FCurrentTurn, False);

  var Winner := BoardWinner;
  if Winner <> #0 then
  begin
    FinishMatch(Winner);
    Exit;
  end;

  // Advance turn
  if FMode = gmPlayerVsPlayer then
  begin
    if FCurrentTurn = 'X' then
      FCurrentTurn := 'O'
    else
      FCurrentTurn := 'X';
  end
  else
  begin
    FCurrentTurn := ComputerMark;
    ComputerMove;
  end;
end;

function TfrmMain.MatchHistoryFilePath: string;
begin
  var ExeName := TPath.GetFileNameWithoutExtension(ParamStr(0));
  if ExeName = '' then
    ExeName := 'TuxTacToe';
  Result := TPath.Combine(TPath.GetDocumentsPath, ExeName + '_MatchHistory.txt');
end;

procedure TfrmMain.LoadMatchHistoryFromFile;
begin
  try
    memMatchHistory.Lines.Clear;
    if TFile.Exists(MatchHistoryFilePath) then
      memMatchHistory.Lines.LoadFromFile(MatchHistoryFilePath);
  except
    // ignore file errors
  end;
end;

procedure TfrmMain.SaveMatchHistoryToFile;
begin
  try
    memMatchHistory.Lines.SaveToFile(MatchHistoryFilePath);
  except
    // ignore file errors
  end;
end;

end.
