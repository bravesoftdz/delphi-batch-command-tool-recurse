// Re:<curse>
// tired of making batch files with excel or a column mode text editor, i wrote this program
// TODO:
// a CLEAR button, COPY ALL button, Save to file... etc
// make the query box a dropdown with some awesome queries in it, fed from text file? lame encoding, wma encoding, cf decrypting, file renaming, csv file generation of mp3 files?
// elite mp3 header extraction? id3, etc.
// jpeg, gif infos?
// make the negative indexing work from the end of a string.
// make second index not required and default it then to string length, and maybe force it to be positive
// if editPath ends in slash then remove it, probably do this onchange?
// make it so you can exit without gettin AV
// would be cool if it could do things like find64, filesizeReport, etc, maybe that's a different program, with plugins for all sorts of stuff
unit main;

interface

uses
  StdCtrls, Buttons, Classes, Controls,
  forms, 		// TForm
  sysutils, // GetCurrentDir
	filectrl; // SelectDirectory

type
  TthreadProcessDir = class;

  TformRecurse = class(TForm)
    memoOutput: TMemo;
    editPath: TEdit;
    editMask: TEdit;
    buttonGo: TBitBtn;
    buttonBrowse: TBitBtn;
    comboQuery: TComboBox;
    procedure init(Sender: TObject);
    procedure buttonGoClick(Sender: TObject);
    procedure buttonBrowseClick(Sender: TObject);
  public
    threadProcessDir: TthreadProcessDir;
  end;

  TthreadProcessDir = class(TThread)
	  theForm : TformRecurse;
    procedure processDir(path: String);
    function formatQuery(path:String; sr: TSearchRec): String;
    constructor Create(CreateSuspended: Boolean; aForm: TformRecurse);
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  formRecurse: TformRecurse;
  dirCount: integer = 0; // symbol I
  // TODO fileCount, symbol J

implementation

{$R *.DFM}

// TformRecurse
//==============================================================================
procedure TformRecurse.init(Sender: TObject);
begin
  editMask.Text := '';
  editPath.Text := GetCurrentDir;
  comboQuery.Text := 'Type or select a query. Don''t worry... nothing is actually executed.';
  comboQuery.Items.Append('wm8eutil -input ":A" -output ":P\:N.wma" -profile a32'); // wma encoding
  comboQuery.Items.Append('lame -b 256 -m s -h ":A" ":P\:N.mp3"'); // lame encoding
  comboQuery.Items.Append('cfdecrypt ":A" ":P\:N.yml"'); // cf decrypt
  comboQuery.Items.Append('echo :F >> ":P\!.m3u"'); // playlister
  comboQuery.Items.Append('rename ":A" ":N<1,8>.:X<1,3>"'); // rename to 8.3
  comboQuery.Items.Append('rename ":A" ":N<1,60>.:X<1,3>"'); // rename to 60.3 < 64
  comboQuery.Items.Append(':A þ :V þ :P þ :F þ :N þ :X þ :B þ :K þ :M þ :D'); // all items
  memoOutput.Clear;
end;

procedure TformRecurse.buttonGoClick(Sender: TObject);
begin
  // TODO: Probably don't need this Resume if I set this true to a false instead!
  threadProcessDir := TthreadProcessDir.Create(true,formRecurse);
  threadProcessDir.Resume;
end;

procedure TformRecurse.buttonBrowseClick(Sender: TObject);
var
  Dir: string;
begin
  if SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate, sdPrompt],1000) then
//  if SelectDirectory('Select Directory',Dir,Dir) then
  // TODO for 1.1 > Cut off trailing slash
  begin
    editPath.Text := Dir;
  end;
end;

// TthreadProcessDir
//==============================================================================
constructor TthreadProcessDir.Create(CreateSuspended: Boolean; aForm: TformRecurse);
begin
  inherited Create(CreateSuspended);
  theForm := aForm;
end;

procedure TthreadProcessDir.Execute;
begin
  processDir(theForm.editPath.Text);
//  theForm.memoOutput.Lines.Append('');
//  theForm.memoOutput.Lines.Append(IntToStr(dirCount) + ' directories processed');
//  theForm.memoOutput.Lines.Append('');
  dirCount := 0;
end;

procedure TthreadProcessDir.processDir(path: String);
var
  sr: TSearchRec;
begin
  dirCount := dirCount + 1;
// theForm.memoOutput.Lines.Append(Path+'\');
//  memoOutput.Lines.Append(Parent.Name);
  if FindFirst(path+'\*', faAnyFile, sr) = 0 then
  begin
    while FindNext(sr) = 0 do
    begin
      // IF not '..' or '.' AND not SysFile, not Hidden, not VolumeID (eg. System Volume Information, IO.SYS, etc)
      if (not (sr.Name = '..')) and (not (sr.Name = '.')) and (sr.attr and (faSysFile or faHidden or faVolumeID) = 0)  then
      begin
        // if dir, process
        // TODO : dir and file checkboxes, determine which will have formatQuery's run on them
        if sr.attr and faDirectory > 0 then
        begin
          processdir(Path+'\'+sr.Name);
        end
        // else file
        else
        begin
          // if ends with mask then we need to work with it
          if CompareText( Copy( sr.Name , Length(sr.Name)-Length(theForm.editMask.Text)+1 , Length(theForm.editMask.Text) ),theForm.editMask.Text) = 0 then
          begin
            //theForm.memoOutput.Lines.Append(path+'\'+sr.Name);
            theForm.memoOutput.Lines.Append(formatQuery(Path,sr));
          end;
        end;
      end;
    end;
  end;
  FindClose(sr);
end;

function TthreadProcessDir.formatQuery(path: String; sr: TSearchRec): String;
var
  qr: String;
  i: Integer;
  subString: String;
  subStart, subStartMarker: Integer;
  subEnd, subEndMarker: Integer;
  queryMarker: Integer;

  recalcI: Integer;
  stupidNameCounter: Integer;

begin
  qr := theForm.comboQuery.Text;
  i := 1;
  stupidNameCounter := 0;

  // loop over qr
  while i <= Length(qr) do
  begin
    //theForm.memoOutput.lines.append('///DEBUG:'+qr+':'+inttostr(i));
    // if qChar found
    if qr[i] = ':' then
    begin
      queryMarker := i;
      i := i + 1; // skip query char %

      // qr[i] here is a char representing the type
      case uppercase(qr[i])[1] of
        '1'..'9': subString:=''; // TODO : file number, type number represents number of columns to use, putting in leading 0's where necessary

        'A': subString:=path + '\' + sr.name; // all name
        'V': subString:=extractfiledrive(path); // drive letter
        // TODO : Directory above (like for use in andrews idea to name the playlist the parent directories name) O or Q
        'P': subString:=path; // path
        'F': subString:=sr.name; // file
        'N':
          begin
            stupidNameCounter:=length(sr.name);
            while stupidNameCounter > 0 do
            begin
              if sr.name[stupidNameCounter] = '.' then
              begin
                subString:=copy(sr.name,1,stupidNameCounter-1); // name only, no extension
                break;
              end;
              stupidNameCounter := stupidNameCounter - 1;
            end;
          end;
        'X':
          begin
            subString:=extractfileext(sr.name); // extension only with period
            if Length(subString) > 0 then
              if subString[1] = '.' then
                subString:=Copy(subString,2,Length(subString)-1);
          end;
        // 'X': subString:=ansistrrscan(PChar(sr.name),'.')+1; // extension only, without period via pointer arithmetic
        'B': subString:=inttostr(sr.size); // size, bytes
        'K': subString:=inttostr(sr.size div 1024); // size, kilo
        'M': subString:=inttostr(sr.size div 1024 div 1024); // size, mega

        'D': subString:=formatdatetime('yyyy-mm-dd',filedatetodatetime(sr.time)); // datetime : TODO : make configurable in options somewhere

        'I': subString:=inttostr(dirCount);
        // TODO for 1.1. > J : file count
        // TODO for 1.1. > T : current time
        // TODO put new symbols in the 'ALL' example
        // Different folder selector?
      else
        subString:= '(null)';
      end;

      // NOTE A: the char for type gets skipped automatically when there is no subindex, via the standard loop counter below

      // if subrange exists then try to parse it
      if qr[i+1] = '<' then // NOTE A: cant skip the type char prematurely
      begin
        i := i + 2; // NOTE A: skip query char for type and [
        subStartMarker := i;

        // find ending '>', parse along the way
        while i <= Length(qr) do
        begin
          // found subStart
          if qr[i] = ',' then
          begin
            subStart := StrToInt(Copy(qr,subStartMarker,i-subStartMarker));
            i := i + 1;
            subEndMarker := i;
          end
          // found subEnd
          else if qr[i] = '>' then
          begin
            subEnd := StrToInt(Copy(qr,subEndMarker,i-subEndMarker));
            break;
          end
          else
          begin
            i := i+1;
          end;
        end;
      end
      else // no subrange
      begin
        subStart := 1;
        subEnd := Length(subString);
      end;

      // replace query with substring, all occurances would break stuff when someone had a query without a subrange first then one with one later
      //theForm.memoOutput.lines.append('///-----:'+Copy(subString,subStart,subEnd-subStart+1)+'<<<'+Copy(qr,queryMarker,i)+'::'+inttostr(querymarker)+'::'+inttostr(i));
      recalcI := length(qr)-i; // calculated as distance left to process
      qr := StringReplace(qr,Copy(qr,queryMarker,i-queryMarker+1),Copy(subString,subStart,subEnd),[rfIgnoreCase]);
      i := length(qr)-recalcI;

    end; // if qChar found

    // inc index counter (TODO, move to end of inserted string if one was inserted)
    i:=i+1; // NOTE A: Standard loop counter

  end; // loop over qr

  Result:= qr;

end;

end.
