unit uStatistics;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  System.IniFiles;

type
  TStatisticsMode = (smPvP, smVsComputer);

  TGameStatistics = class
  private
    FFilePath: string;

    FSessionStart: TDateTime;

    FMatchesStarted: Integer;
    FMatchesFinished: Integer;
    FMatchesAbandoned: Integer;

    FPvPStarted: Integer;
    FPvPFinished: Integer;
    FVsComputerStarted: Integer;
    FVsComputerFinished: Integer;

    FWinsX: Integer;
    FWinsO: Integer;
    FDraws: Integer;

    FPlayerWins: Integer;
    FComputerWins: Integer;

    FCurrentPlayerWinStreak: Integer;
    FBestPlayerWinStreak: Integer;
    FCurrentComputerWinStreak: Integer;
    FBestComputerWinStreak: Integer;

    FTotalMoves: Integer;
    FTotalMovesX: Integer;
    FTotalMovesO: Integer;
    FPlayerMoves: Integer;
    FComputerMoves: Integer;

    FMinMovesPerFinishedMatch: Integer;
    FMaxMovesPerFinishedMatch: Integer;

    FTotalFinishedMatchSeconds: Int64;
    FMinFinishedMatchSeconds: Int64;
    FMaxFinishedMatchSeconds: Int64;

    FCellPlays: array[1..9] of Integer;

    FStartCellCounts: array[1..9] of Integer;
    FWinsWhenStartedCell: array[1..9] of Integer;
    FCurrentMatchStartCell: Integer; // non-persistent: this match's starting cell
    FLastStartCell: Integer;
    FConsecutiveSameStartCount: Integer;
    FAggressiveStartSequences: Integer; // times reached 10 consecutive same starts
    FFirstPlayerMoveDone: Boolean;
    FQuickVictoryCount: Integer;
    FLastMoveHeroCount: Integer;
    FMatchesWhereOpponentPlacedCenter: Integer; // overall count of matches where an opponent placed center

    // Invalid click tracking removed

    // current match state (not persisted)
    FMatchInProgress: Boolean;
    FMatchStartTime: TDateTime;
    FMatchMoves: Integer;
    FMatchMode: TStatisticsMode;
    FCurrentMatchOpponentPlacedCenter: Boolean;

    procedure ClearNonPersistentMatchState;

    procedure LoadFromIni(Ini: TIniFile);
    procedure SaveToIni(Ini: TIniFile);

    class function ReadInt64(Ini: TIniFile; const Section, Ident: string; DefaultValue: Int64): Int64; static;
    class procedure WriteInt64(Ini: TIniFile; const Section, Ident: string; Value: Int64); static;

    function SafeDiv(Numerator, Denominator: Int64): Double;
    procedure AutoSave;
  public
    constructor Create(const FilePath: string);

    procedure StartNewSession;

    procedure Load;
    procedure Save;

    procedure RecordMatchStarted(Mode: TStatisticsMode);
    procedure RecordMatchAbandoned;
    procedure RecordMove(TileIndex: Integer; Mark: Char; ByComputer: Boolean);
    procedure RecordMatchFinished(Winner, Who: Char; Mode: TStatisticsMode);
    // RecordInvalidClick removed

    procedure BuildStatisticsLines(Lines: TStrings);

    property SessionStart: TDateTime read FSessionStart;
    property FilePath: string read FFilePath;
  end;

implementation

{ TGameStatistics }

constructor TGameStatistics.Create(const FilePath: string);
begin
  inherited Create;
  FFilePath := FilePath;
  StartNewSession;
end;

procedure TGameStatistics.StartNewSession;
begin
  FSessionStart := Now;
  ClearNonPersistentMatchState;
end;

procedure TGameStatistics.ClearNonPersistentMatchState;
begin
  FMatchInProgress := False;
  FMatchStartTime := 0;
  FMatchMoves := 0;
  FMatchMode := smPvP;
  FCurrentMatchStartCell := 0;
  FCurrentMatchOpponentPlacedCenter := False;
end;

class function TGameStatistics.ReadInt64(Ini: TIniFile; const Section, Ident: string; DefaultValue: Int64): Int64;
begin
  Result := StrToInt64Def(Ini.ReadString(Section, Ident, IntToStr(DefaultValue)), DefaultValue);
end;

class procedure TGameStatistics.WriteInt64(Ini: TIniFile; const Section, Ident: string; Value: Int64);
begin
  Ini.WriteString(Section, Ident, IntToStr(Value));
end;

function TGameStatistics.SafeDiv(Numerator, Denominator: Int64): Double;
begin
  if Denominator = 0 then
    Exit(0);
  Result := Numerator / Denominator;
end;

procedure TGameStatistics.AutoSave;
begin
  // Persist often; file is tiny and avoids losing stats on crash.
  Save;
end;

procedure TGameStatistics.Load;
begin
  if FFilePath = '' then
    Exit;
  if not FileExists(FFilePath) then
    Exit;

  var Ini := TIniFile.Create(FFilePath);
  try
    LoadFromIni(Ini);
  finally
    Ini.Free;
  end;

  // Never restore an in-progress match from disk.
  ClearNonPersistentMatchState;
end;

procedure TGameStatistics.Save;
begin
  if FFilePath = '' then
    Exit;

  var Ini := TIniFile.Create(FFilePath);
  try
    SaveToIni(Ini);
  finally
    Ini.Free;
  end;
end;

procedure TGameStatistics.LoadFromIni(Ini: TIniFile);
begin
  FMatchesStarted := Ini.ReadInteger('Matches', 'Started', 0);
  FMatchesFinished := Ini.ReadInteger('Matches', 'Finished', 0);
  FMatchesAbandoned := Ini.ReadInteger('Matches', 'Abandoned', 0);

  FPvPStarted := Ini.ReadInteger('Modes', 'PvPStarted', 0);
  FPvPFinished := Ini.ReadInteger('Modes', 'PvPFinished', 0);
  FVsComputerStarted := Ini.ReadInteger('Modes', 'VsComputerStarted', 0);
  FVsComputerFinished := Ini.ReadInteger('Modes', 'VsComputerFinished', 0);

  FWinsX := Ini.ReadInteger('Results', 'WinsX', 0);
  FWinsO := Ini.ReadInteger('Results', 'WinsO', 0);
  FDraws := Ini.ReadInteger('Results', 'Draws', 0);

  FPlayerWins := Ini.ReadInteger('VsComputer', 'PlayerWins', 0);
  FComputerWins := Ini.ReadInteger('VsComputer', 'ComputerWins', 0);
  FCurrentPlayerWinStreak := Ini.ReadInteger('VsComputer', 'CurrentPlayerWinStreak', 0);
  FBestPlayerWinStreak := Ini.ReadInteger('VsComputer', 'BestPlayerWinStreak', 0);
  FCurrentComputerWinStreak := Ini.ReadInteger('VsComputer', 'CurrentComputerWinStreak', 0);
  FBestComputerWinStreak := Ini.ReadInteger('VsComputer', 'BestComputerWinStreak', 0);

  FTotalMoves := Ini.ReadInteger('Moves', 'TotalMoves', 0);
  FTotalMovesX := Ini.ReadInteger('Moves', 'TotalMovesX', 0);
  FTotalMovesO := Ini.ReadInteger('Moves', 'TotalMovesO', 0);
  FPlayerMoves := Ini.ReadInteger('Moves', 'PlayerMoves', 0);
  FComputerMoves := Ini.ReadInteger('Moves', 'ComputerMoves', 0);
  FMinMovesPerFinishedMatch := Ini.ReadInteger('Moves', 'MinMovesPerFinishedMatch', 0);
  FMaxMovesPerFinishedMatch := Ini.ReadInteger('Moves', 'MaxMovesPerFinishedMatch', 0);

  FTotalFinishedMatchSeconds := ReadInt64(Ini, 'Timing', 'TotalFinishedMatchSeconds', 0);
  FMinFinishedMatchSeconds := ReadInt64(Ini, 'Timing', 'MinFinishedMatchSeconds', 0);
  FMaxFinishedMatchSeconds := ReadInt64(Ini, 'Timing', 'MaxFinishedMatchSeconds', 0);

  for var I := 1 to 9 do
    FCellPlays[I] := Ini.ReadInteger('Cells', 'Cell' + IntToStr(I), 0);

  for var I := 1 to 9 do
    FStartCellCounts[I] := Ini.ReadInteger('Starts', 'StartCell' + IntToStr(I), 0);

  for var I := 1 to 9 do
    FWinsWhenStartedCell[I] := Ini.ReadInteger('Starts', 'WinsWhenStartCell' + IntToStr(I), 0);

  FLastStartCell := Ini.ReadInteger('Starts', 'LastStartCell', 0);
  FConsecutiveSameStartCount := Ini.ReadInteger('Starts', 'ConsecutiveSameStartCount', 0);
  FAggressiveStartSequences := Ini.ReadInteger('Starts', 'AggressiveStartSequences', 0);
  FFirstPlayerMoveDone := Ini.ReadBool('Flags', 'FirstPlayerMoveDone', False);
  FQuickVictoryCount := Ini.ReadInteger('Special', 'QuickVictoryCount', 0);
  FLastMoveHeroCount := Ini.ReadInteger('Special', 'LastMoveHeroCount', 0);
  FMatchesWhereOpponentPlacedCenter := Ini.ReadInteger('Special', 'MatchesWhereOpponentPlacedCenter', 0);

  // Invalid click values removed
end;

procedure TGameStatistics.SaveToIni(Ini: TIniFile);
begin
  Ini.WriteInteger('Matches', 'Started', FMatchesStarted);
  Ini.WriteInteger('Matches', 'Finished', FMatchesFinished);
  Ini.WriteInteger('Matches', 'Abandoned', FMatchesAbandoned);

  Ini.WriteInteger('Modes', 'PvPStarted', FPvPStarted);
  Ini.WriteInteger('Modes', 'PvPFinished', FPvPFinished);
  Ini.WriteInteger('Modes', 'VsComputerStarted', FVsComputerStarted);
  Ini.WriteInteger('Modes', 'VsComputerFinished', FVsComputerFinished);

  Ini.WriteInteger('Results', 'WinsX', FWinsX);
  Ini.WriteInteger('Results', 'WinsO', FWinsO);
  Ini.WriteInteger('Results', 'Draws', FDraws);

  Ini.WriteInteger('VsComputer', 'PlayerWins', FPlayerWins);
  Ini.WriteInteger('VsComputer', 'ComputerWins', FComputerWins);
  Ini.WriteInteger('VsComputer', 'CurrentPlayerWinStreak', FCurrentPlayerWinStreak);
  Ini.WriteInteger('VsComputer', 'BestPlayerWinStreak', FBestPlayerWinStreak);
  Ini.WriteInteger('VsComputer', 'CurrentComputerWinStreak', FCurrentComputerWinStreak);
  Ini.WriteInteger('VsComputer', 'BestComputerWinStreak', FBestComputerWinStreak);

  Ini.WriteInteger('Moves', 'TotalMoves', FTotalMoves);
  Ini.WriteInteger('Moves', 'TotalMovesX', FTotalMovesX);
  Ini.WriteInteger('Moves', 'TotalMovesO', FTotalMovesO);
  Ini.WriteInteger('Moves', 'PlayerMoves', FPlayerMoves);
  Ini.WriteInteger('Moves', 'ComputerMoves', FComputerMoves);
  Ini.WriteInteger('Moves', 'MinMovesPerFinishedMatch', FMinMovesPerFinishedMatch);
  Ini.WriteInteger('Moves', 'MaxMovesPerFinishedMatch', FMaxMovesPerFinishedMatch);

  WriteInt64(Ini, 'Timing', 'TotalFinishedMatchSeconds', FTotalFinishedMatchSeconds);
  WriteInt64(Ini, 'Timing', 'MinFinishedMatchSeconds', FMinFinishedMatchSeconds);
  WriteInt64(Ini, 'Timing', 'MaxFinishedMatchSeconds', FMaxFinishedMatchSeconds);

  for var I := 1 to 9 do
    Ini.WriteInteger('Cells', 'Cell' + IntToStr(I), FCellPlays[I]);

  for var I := 1 to 9 do
    Ini.WriteInteger('Starts', 'StartCell' + IntToStr(I), FStartCellCounts[I]);

  for var I := 1 to 9 do
    Ini.WriteInteger('Starts', 'WinsWhenStartCell' + IntToStr(I), FWinsWhenStartedCell[I]);

  Ini.WriteInteger('Starts', 'LastStartCell', FLastStartCell);
  Ini.WriteInteger('Starts', 'ConsecutiveSameStartCount', FConsecutiveSameStartCount);
  Ini.WriteInteger('Starts', 'AggressiveStartSequences', FAggressiveStartSequences);
  Ini.WriteBool('Flags', 'FirstPlayerMoveDone', FFirstPlayerMoveDone);
  Ini.WriteInteger('Special', 'QuickVictoryCount', FQuickVictoryCount);
  Ini.WriteInteger('Special', 'LastMoveHeroCount', FLastMoveHeroCount);
  Ini.WriteInteger('Special', 'MatchesWhereOpponentPlacedCenter', FMatchesWhereOpponentPlacedCenter);
  // Invalid click values removed
end;

procedure TGameStatistics.RecordMatchStarted(Mode: TStatisticsMode);
begin
  Inc(FMatchesStarted);
  if Mode = smPvP then
    Inc(FPvPStarted)
  else
    Inc(FVsComputerStarted);

  FMatchInProgress := True;
  FMatchStartTime := Now;
  FMatchMoves := 0;
  FMatchMode := Mode;

  AutoSave;
end;

procedure TGameStatistics.RecordMatchAbandoned;
begin
  if not FMatchInProgress then
    Exit;

  Inc(FMatchesAbandoned);
  ClearNonPersistentMatchState;
  AutoSave;
end;

procedure TGameStatistics.RecordMove(TileIndex: Integer; Mark: Char; ByComputer: Boolean);
begin
  if not CharInSet(Mark, ['X', 'O']) then
    Exit;
  if (TileIndex < 1) or (TileIndex > 9) then
    Exit;

  Inc(FTotalMoves);
  Inc(FTotalMoves);
  // If this is the very first move of the match, record starting cell
  if FMatchMoves = 0 then
  begin
    FCurrentMatchStartCell := TileIndex;
    Inc(FStartCellCounts[TileIndex]);
    if TileIndex = FLastStartCell then
      Inc(FConsecutiveSameStartCount)
    else
      FConsecutiveSameStartCount := 1;
    FLastStartCell := TileIndex;
    if FConsecutiveSameStartCount >= 10 then
      Inc(FAggressiveStartSequences);
  end;

  Inc(FMatchMoves);

  if Mark = 'X' then
    Inc(FTotalMovesX)
  else
    Inc(FTotalMovesO);

  if ByComputer then
    Inc(FComputerMoves)
  else
    Inc(FPlayerMoves);

  Inc(FCellPlays[TileIndex]);
  AutoSave;
end;

procedure TGameStatistics.RecordMatchFinished(Winner, Who: Char; Mode: TStatisticsMode);
begin
  Inc(FMatchesFinished);
  if Mode = smPvP then
    Inc(FPvPFinished)
  else
    Inc(FVsComputerFinished);

  case Winner of
    'X': Inc(FWinsX);
    'O': Inc(FWinsO);
    '=': Inc(FDraws);
  end;

  if Mode = smVsComputer then
  begin
    if Winner = '=' then
    begin
      FCurrentPlayerWinStreak := 0;
      FCurrentComputerWinStreak := 0;
    end
    else if (Who = 'P') then
    begin
      Inc(FPlayerWins);
      Inc(FCurrentPlayerWinStreak);
      FCurrentComputerWinStreak := 0;
      if FCurrentPlayerWinStreak > FBestPlayerWinStreak then
        FBestPlayerWinStreak := FCurrentPlayerWinStreak;
    end
    else if (Who = 'C') then
    begin
      Inc(FComputerWins);
      Inc(FCurrentComputerWinStreak);
      FCurrentPlayerWinStreak := 0;
      if FCurrentComputerWinStreak > FBestComputerWinStreak then
        FBestComputerWinStreak := FCurrentComputerWinStreak;
    end;
  end;

  if FMatchMoves > 0 then
  begin
    if (FMinMovesPerFinishedMatch = 0) or (FMatchMoves < FMinMovesPerFinishedMatch) then
      FMinMovesPerFinishedMatch := FMatchMoves;
    if (FMaxMovesPerFinishedMatch = 0) or (FMatchMoves > FMaxMovesPerFinishedMatch) then
      FMaxMovesPerFinishedMatch := FMatchMoves;
  end;

  if FMatchStartTime > 0 then
  begin
    var Seconds := SecondsBetween(Now, FMatchStartTime);
    FTotalFinishedMatchSeconds := FTotalFinishedMatchSeconds + Seconds;
    if (FMinFinishedMatchSeconds = 0) or (Seconds < FMinFinishedMatchSeconds) then
      FMinFinishedMatchSeconds := Seconds;
    if (FMaxFinishedMatchSeconds = 0) or (Seconds > FMaxFinishedMatchSeconds) then
      FMaxFinishedMatchSeconds := Seconds;
  end;


    // Special achievement-related stats
    if FMatchMoves <= 3 then
      Inc(FQuickVictoryCount);

    if FMatchMoves >= 9 then
      Inc(FLastMoveHeroCount);

    if (FCurrentMatchStartCell >= 1) and (Winner <> '=') then
      Inc(FWinsWhenStartedCell[FCurrentMatchStartCell]);

    if FCurrentMatchOpponentPlacedCenter then
      Inc(FMatchesWhereOpponentPlacedCenter);

  ClearNonPersistentMatchState;
  AutoSave;
end;

procedure TGameStatistics.BuildStatisticsLines(Lines: TStrings);
begin
  if Lines = nil then
    Exit;

  Lines.BeginUpdate;
  try
    Lines.Clear;

    var SessionSeconds := SecondsBetween(Now, FSessionStart);
    Lines.Add('Session');
    Lines.Add('  Started: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FSessionStart));
    Lines.Add('  Duration: ' + IntToStr(SessionSeconds) + 's');
    Lines.Add('');

    Lines.Add('Matches');
    Lines.Add('  Started: ' + IntToStr(FMatchesStarted));
    Lines.Add('  Finished: ' + IntToStr(FMatchesFinished));
    Lines.Add('  Abandoned: ' + IntToStr(FMatchesAbandoned));
    Lines.Add('  In progress: ' + BoolToStr(FMatchInProgress, True));
    if FMatchInProgress then
    begin
      Lines.Add('  Current match started: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FMatchStartTime));
      Lines.Add('  Current match moves: ' + IntToStr(FMatchMoves));
    end;
    Lines.Add('');

    Lines.Add('Modes');
    Lines.Add('  PvP started: ' + IntToStr(FPvPStarted));
    Lines.Add('  PvP finished: ' + IntToStr(FPvPFinished));
    Lines.Add('  Vs Computer started: ' + IntToStr(FVsComputerStarted));
    Lines.Add('  Vs Computer finished: ' + IntToStr(FVsComputerFinished));
    Lines.Add('');

    Lines.Add('Results');
    Lines.Add('  X wins: ' + IntToStr(FWinsX));
    Lines.Add('  O wins: ' + IntToStr(FWinsO));
    Lines.Add('  Draws: ' + IntToStr(FDraws));
    Lines.Add('  Win rate (non-draw): ' + FormatFloat('0.0%', SafeDiv(FWinsX + FWinsO, FMatchesFinished) * 100));
    Lines.Add('');

    Lines.Add('Vs Computer');
    Lines.Add('  Player wins: ' + IntToStr(FPlayerWins));
    Lines.Add('  Computer wins: ' + IntToStr(FComputerWins));
    Lines.Add('  Current player win streak: ' + IntToStr(FCurrentPlayerWinStreak));
    Lines.Add('  Best player win streak: ' + IntToStr(FBestPlayerWinStreak));
    Lines.Add('  Current computer win streak: ' + IntToStr(FCurrentComputerWinStreak));
    Lines.Add('  Best computer win streak: ' + IntToStr(FBestComputerWinStreak));
    Lines.Add('');

    Lines.Add('Moves');
    Lines.Add('  Total moves: ' + IntToStr(FTotalMoves));
    Lines.Add('  X moves: ' + IntToStr(FTotalMovesX));
    Lines.Add('  O moves: ' + IntToStr(FTotalMovesO));
    Lines.Add('  Player moves: ' + IntToStr(FPlayerMoves));
    Lines.Add('  Computer moves: ' + IntToStr(FComputerMoves));
    Lines.Add('  Avg moves / finished match: ' + FormatFloat('0.00', SafeDiv(FTotalMoves, FMatchesFinished)));
    Lines.Add('  Min moves / finished match: ' + IntToStr(FMinMovesPerFinishedMatch));
    Lines.Add('  Max moves / finished match: ' + IntToStr(FMaxMovesPerFinishedMatch));
    Lines.Add('');

    Lines.Add('Timing');
    Lines.Add('  Total finished match time: ' + IntToStr(FTotalFinishedMatchSeconds) + 's');
    Lines.Add('  Avg seconds / finished match: ' + FormatFloat('0.00', SafeDiv(FTotalFinishedMatchSeconds, FMatchesFinished)));
    Lines.Add('  Fastest finished match: ' + IntToStr(FMinFinishedMatchSeconds) + 's');
    Lines.Add('  Longest finished match: ' + IntToStr(FMaxFinishedMatchSeconds) + 's');
    Lines.Add('');

    Lines.Add('Board');
    for var I := 1 to 9 do
      Lines.Add('  Cell ' + IntToStr(I) + ' plays: ' + IntToStr(FCellPlays[I]));
    Lines.Add('');

    Lines.Add('Starts');
    for var J := 1 to 9 do
      Lines.Add('  Start cell ' + IntToStr(J) + ': ' + IntToStr(FStartCellCounts[J]) + ' starts, ' + IntToStr(FWinsWhenStartedCell[J]) + ' wins when started');
    Lines.Add('  Last start cell: ' + IntToStr(FLastStartCell));
    Lines.Add('  Consecutive same start count: ' + IntToStr(FConsecutiveSameStartCount));
    Lines.Add('  Aggressive start sequences (>=10): ' + IntToStr(FAggressiveStartSequences));
    Lines.Add('');

    Lines.Add('Special');
    Lines.Add('  First player move ever made: ' + BoolToStr(FFirstPlayerMoveDone, True));
    Lines.Add('  Quick victories (<=3 moves): ' + IntToStr(FQuickVictoryCount));
    Lines.Add('  Last-move hero wins (won on final cell): ' + IntToStr(FLastMoveHeroCount));
    Lines.Add('  Matches where opponent placed center: ' + IntToStr(FMatchesWhereOpponentPlacedCenter));
    Lines.Add('');

    // Invalid clicks section removed
  finally
    Lines.EndUpdate;
  end;
end;

end.
