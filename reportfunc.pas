{
*****************************************************************
  reportfunc.pas
  functions library for use in Linux OS with Russian UTF8 charset
  author's: Eugene /gNEV/ Nazarov
  for free use
*****************************************************************
}

unit reportfunc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType, Variants, LCLProc;
  
  function Pol(const Name,Otch:string):TUTF8Char;
  function ShotFIO(const LengthFIO:string):string;
  function WordUpperCase(const Atext:string):string;
  function FIOPadezh(const Fam,Name,Otch:string;Padezh:TUTF8Char):string;
  function GetChar(const Slovo:string;index:integer):TUTF8Char;
  function DateForReport(Chislo:TDateTime):string;
  function SummaProp(SummaSch:Currency;Kop:boolean = False;Rub:boolean = False):string;
  function KopToStr(M:Currency;Kopstr:boolean = False):string;
  function Kopejki(const Kop:string):string;
  procedure BreakFIO(const FIO:string;var Fam,Name,Otch:string);
  function StrokaRazbivka(const stroka:string;var stroka2:string;KolZnakov:integer = 32):string;

implementation
const
  BLANK = ' ';

//функция определения пола по отчеству или имени
function Pol(const Name,Otch:string):TUTF8Char;
var
  Okonch:string;
begin
  Result:=' ';
  if Otch <> '' then
    begin
      Okonch:=UTF8Copy(Otch,UTF8Length(Otch),1);
      if Okonch = 'ч' then Result:='М'
      else Result:='Ж';
    end
  else
    begin
      if Name <> '' then
        begin
          Okonch:=UTF8Copy(Name,UTF8Length(Name),1);
          if  (Okonch = 'а') or (Okonch = 'я') then
          Result:='Ж'
          else Result:='М';
        end;
    end;
end; 


//Функция получения краткого написания ФИО, т.е. Петров А.А.
//вместо Петров Александр Александрович
function ShotFIO(const LengthFIO:string):string;
var
  AName,TempFIO:string;
begin
  Result:='';
  if LengthFIO = '' then Exit;
  TempFIO:=LengthFIO;
  TempFIO:=Trim(TempFIO);
  if UTF8pos(' ',TempFIO) <= 0 then
    begin
      Result:=TempFIO;
      Exit;
    end;
  Result:=UTF8Copy(TempFIO,0,UTF8pos(' ',TempFIO)-1)+' ';
  UTF8Delete(TempFIO,1,UTF8pos(' ',TempFIO));
  if UTF8pos(' ',TempFIO) <= 0 then
    begin
      AName:=TempFIO ;
      UTF8Delete(AName,2,UTF8Length(AName));
      Result:=Result+AName+'.';
      Exit;
    end
  else
    AName:=UTF8Copy(TempFIO,0,UTF8pos(' ',TempFIO)-1);
  UTF8Delete(TempFIO,1,UTF8pos(' ',TempFIO));
  UTF8Delete(AName,2,UTF8Length(AName));
  UTF8Delete(TempFIO,2,UTF8Length(TempFIO));
  Result:=Result+AName+'.'+TempFIO+'.'
end;


//Функция преобразования русской буквы в заглавную в слове, возвращает слово с заглавной буквой
//аналог NameCase в Lasreport
function WordUpperCase(const Atext:string):string;
var
  TempText:string;
begin
  Result:='';
  if Atext = '' then Exit;
  TempText:=AText;
  TempText:=UTF8LowerCase(TrimLeft(TempText));
  Result:=UTF8Uppercase(UTF8Copy(TempText,0,1))+UTF8Copy(TempText,2,UTF8Length(TempText));
end;


//функция (распространенных фамилий)склонения ФИО в родительном и дательном падежах (кого,кому?)
//Padezh - R-родительный (заявление от кого?), D-дательный (поручить кому?) ,T-творительный (невозможно сделать полностью корректно)(заменить кем?)
//V-винительный (принять на работу кого?)
//не панацея!!! всегда проверяем!
function FIOPadezh(const Fam,Name,Otch:string;Padezh:TUTF8Char):string;
//функция вытаскивания фамилии из ФИО (фактически не нужна, но оставил...)
function FamOut(var FIO:string):string;
begin
   if (UTF8Pos(' ',FIO)=0) then
   begin
     Result:=FIO;
     Exit;
   end
   else
     Result:=UTF8Copy(FIO,1,UTF8Pos(' ',FIO)-1);
   UTF8Delete(FIO,1,UTF8Pos(' ',FIO));
end;
//функция удаления окончания
function OkDelete(const Slovo:string;Simv:Byte):string;
var
  ASlovo:string;
begin
  ASlovo:=Slovo;
  UTF8Delete(ASlovo,UTF8Length(ASlovo)-(Simv-1),Simv);
  Result:=ASlovo;
end;
//процедура получения окончания в виде буквы или двух букв
procedure Okonchanie(var Buk:TUTF8Char;var Okonch:string;const Slovo:string);
begin
  Buk:=UTF8Copy(Slovo,UTF8Length(Slovo),1);
  Okonch:=UTF8Copy(Slovo,UTF8Length(Slovo)-1,2);
end;

//функции проверки вхождения букв вместо конструкции set of
// AType= Glasn=0;Soglasn=1;Nesklonglas=2;NesklonOk=3;Sklsoglas=4
function Bukvi(ABuk:TUTF8Char;AType:byte):boolean;
begin
  Result:=False;
  case AType of
  0:case ABuk of
    'е','э','и','ы','у','ю','о','а','я','ё':Result:=True;
    end;
  1:case ABuk of
    'б','п','в','ф','д','т','з','с','ж','ш','ч','ц','щ','г','к','х','м','н','л','р':Result:=True;
    end;
  2:case ABuk of
    'е','э','и','ы','у','ю','о':Result:=True;
    end;
  3:case ABuk of
    'х','а','я':Result:=True;
    end;
  4:case ABuk of
    'б','в','г','д','ж','з','к','л','м','н','п','р','с','т','ф','ц','ч','ш','щ','ь','й':Result:=True;
    end;
end;
end;
var
Bukok:TUTF8Char;
ok,F,N,O,AFIO,bezok:string;
begin
  Result:='';
  F:=Fam; N:=Name; O:=Otch;
  if (N = '')and(O = '') then
  begin
    AFIO:=Fam;
    F:=FamOut(AFIO);
    //N:=FamOut(AFIO);
    //O:=FamOut(AFIO);
  end;
  //убираем мусор
  F:=Trim(F);
  N:=Trim(N);
  O:=Trim(O);
  //добываем окончание  фамилии
  Okonchanie(Bukok,ok,F);
  if Bukvi(Bukok,2) then Result:=F; //не склоняется ни мужская ни женская
  if Pol(N,O)= 'М' then
    begin
    //мужская фамилия
      if Bukvi(Bukok,3) then
        if (ok = 'ых')or (ok = 'их')or(ok = 'уа')or(ok = 'иа')then
          Result:=F //не склоняется
        else
          case Bukok of //склоняемые фамилии на "а" и "х" и "я"
          'х': case Padezh of
               'R','V':Result:=F+'а';
                   'D':Result:=F+'у';
                   'T':Result:=F+'ом';
               end;
          'а','я': if GetChar(ok,1) = 'и' then Result:=F //не склоняются
                   else
                    begin
                     bezok:=OkDelete(F,1);
                     case Padezh of
                     'R':Result:=bezok+'и';
                     'V':Result:=bezok+'ю';
                     'D':Result:=bezok+'е';
                     'T':Result:=F;//оставляем фамилию не склоняя
                     end;
                   end;
          end;//case на "а" и "х"
      if Bukvi(Bukok,4) then
          case Bukok of
          //исключения
          'й': begin
                 bezok:=OkDelete(F,2);
                 case Padezh of
                   'R','V':Result:=bezok+'ого';
                       'D':Result:=bezok+'ому';
                       'T':Result:=bezok+'им';
                   end;
               end;
          'к': if ok = 'ок' then
                 begin
                   bezok:=OkDelete(F,2);
                   case Padezh of
                   'R','V':Result:=bezok+'ка';
                       'D':Result:=bezok+'ку';
                       'T':Result:=bezok+'ком';
                   end;
                 end
                 else
                   case Padezh of
                   'R','V':Result:=F+'а';
                       'D':Result:=F+'у';
                       'T':Result:=F+'ом';
                   end;
          'ь': begin
                 bezok:=OkDelete(F,1);
                 case Padezh of
                   'R','V':Result:=bezok+'я';
                       'D':Result:=bezok+'ю';
                       'T':Result:=bezok+'ем';
                   end;
               end
          else
            case Padezh of
            'R','V': Result:=F+'а';
                'D': Result:=F+'у';
                'T': Result:=F+'ым';
            end;//case Padezh
          end; //case сколняемые мужские на согласные
    //мужское имя
      Okonchanie(Bukok,ok,N);
      if Bukvi(Bukok,2) then Result:=Result+BLANK+N;//не склоняется
      if Bukvi(Bukok,4) then
        //исключения
        case Bukok of
        'й','ь': begin
                   bezok:=OkDelete(N,1);
                   case Padezh of
                   'R','V':Result:=Result+BLANK+bezok+'я';
                       'D':Result:=Result+BLANK+bezok+'ю';
                       'T':Result:=Result+BLANK+bezok+'ем';
                   end;
                 end;
            'л': begin
                  if N = 'Павел' then
                  case Padezh of
                   'R','V':Result:=Result+BLANK+'Павла';
                       'D':Result:=Result+BLANK+'Павлу';
                       'T':Result:=Result+BLANK+'Павлом';
                  end;
                 end
        else
          case Padezh of
          'R','V':Result:=Result+BLANK+N+'а';
              'D':Result:=Result+BLANK+N+'у';
              'T':Result:=Result+BLANK+N+'ом';
          end;
        end;//case
      if Bukvi(Bukok,3) then
        case Bukok of
        'а','я': begin
                   bezok:=OkDelete(N,1);
                   case Padezh of
                   'R':begin
                         if N = 'Лука' then //исключение
                           Result:=Result+BLANK+bezok+'и'
                         else
                           Result:=Result+BLANK+bezok+'ы';//не всегда в родительном (Лука-ЛукИ,Никита-НикитЫ!!!
                       end;
                   'V':Result:=Result+BLANK+bezok+'у';
                   'D':Result:=Result+BLANK+bezok+'е';
                   'T':Result:=Result+BLANK+bezok+'ой';
                   end;
                 end
        else
          case Padezh of
          'R','V':Result:=Result+BLANK+N+'а';
              'D':Result:=Result+BLANK+N+'у';
              'T':Result:=Result+BLANK+N+'ом';
          end;
          if Padezh='D'then else
        end;
    //мужское отчество
      if O <> '' then
        case Padezh of
        'R','V':Result:=Result+BLANK+O+'а';
            'D':Result:=Result+BLANK+O+'у';
            'T':Result:=Result+BLANK+O+'ем';
        end;
    end
  else
  //женская фамилия
    begin
      if Bukvi(Bukok,4) then Result:=F; //не склоняются
      if Bukvi(Bukok,3) then 
        case Bukok of
        'а':  if GetChar(ok,1) = 'и' then Result:=F //не склоняются
              else
                begin
                  bezok:=OkDelete(F,1);
                  case Padezh of
                  'R','D','T':Result:=bezok+'ой';
                          'V':Result:=bezok+'у';
                  end;
                end;
        'я':  if GetChar(ok,1) = 'и' then Result:=F//не склоняются
              else
               begin
               if Bukvi(GetChar(ok,1),1) then
                 begin
                   bezok:=OkDelete(F,1);
                   case Padezh of
                   'R':Result:=bezok+'и';
                   'D':Result:=bezok+'е';
                   'T':begin
                         bezok:=OkDelete(F,1);
                         Result:=bezok+'ей';
                       end;
                   'V':Result:=bezok+'ю';
                   end;
                 end
               else
                 begin
                   bezok:=OkDelete(F,2);
                   case Padezh of
                   'R','D','T':Result:=bezok+'ой';
                           'V':Result:=bezok+'ую';
                   end;
                 end;
             end;
        'х':Result:=F;//не склоняется
        end;//case
    //женское имя
      Okonchanie(Bukok,ok,N);//не склоняются
      if Bukvi(Bukok,4) then 
        //исключение
        case Bukok of
        'ь':begin
              bezok:=OkDelete(N,1);
              case Padezh of
              'R','D':Result:=Result+BLANK+bezok+'и';
              'T','V':Result:=Result+BLANK+N;
              end;
            end
        else
          Result:=Result+BLANK+N;
        end;//case
      if Bukvi(Bukok,3) then
        case Bukok of
        'а':begin
              bezok:=OkDelete(N,1);
              case Padezh of
              'R':Result:=Result+BLANK+bezok+'ы';
              'V':Result:=Result+BLANK+bezok+'у';
              'D':Result:=Result+BLANK+bezok+'е';
              'T':Result:=Result+BLANK+bezok+'ой';
              end;
            end;
        'я':begin
              if ok = 'ия' then
                begin
                  bezok:=OkDelete(N,1);
                  case Padezh of
                  'R','D':Result:=Result+BLANK+bezok+'и';
                      'V':Result:=Result+BLANK+bezok+'ю';
                      'T':Result:=Result+BLANK+bezok+'ей';
                  end;
                end
              else
                begin
                  bezok:=OkDelete(N,1);
                  case Padezh of
                  'R','D':Result:=Result+BLANK+bezok+'е';
                      'V':Result:=Result+BLANK+bezok+'ю';
                      'T':Result:=Result+BLANK+bezok+'ей';
                  end;
                end;
            end
        else
          Result:=Result+BLANK+N;
        end;//case
      if Bukvi(Bukok,2) then Result:=Result+BLANK+N;
    //женское отчество
      if O <> '' then
        begin
         bezok:=OkDelete(O,1);
         case Padezh of
         'R':Result:=Result+BLANK+bezok+'ы';
         'V':Result:=Result+BLANK+bezok+'у';
         'D':Result:=Result+BLANK+bezok+'е';
         'T':Result:=Result+BLANK+bezok+'ой';
         end;
        end;
    end;
end;


//функция возвращает букву в в заданном слове в соответствии с индексом
// вместо slovo[1ndex]
function GetChar(const Slovo:string;index:integer):TUTF8Char;
begin
  Result:=UTF8Copy(Slovo,index,1);
end;



//функция преобразования даты в формат документов
function DateForReport(Chislo:TDateTime):string;
const
  AMonths: array [1..12] of string =('января','февраля','марта','апреля','мая',
                                     'июня','июля','августа','сентября','октября',
                                     'ноября','декабря');
  Lquote='«';
  Rquote='»';
var
AYear,AMonth,ADay:Word;
begin
  DecodeDate(Chislo,AYear,AMonth,ADay);
  if ADay < 10 then
    Result:=Lquote+'0'+IntToStr(ADay)+Rquote+BLANK+AMonths[AMonth]+BLANK+IntToStr(AYear)+' г.'
  else
    Result:=Lquote+IntToStr(ADay)+Rquote+BLANK+AMonths[AMonth]+BLANK+IntToStr(AYear)+' г.';
end;


//Функция суммы прописи  (до миллиарда)
//Kop = True добавляет копейки суммы SummaSch в сумме прописью (со словом 'копеек')
//Rub = True - добавляет  слово 'рублей'  в конец  суммы прописи
function SummaProp(SummaSch:Currency;Kop:boolean = False;Rub:boolean = False):string;
function Desjatki(Razrjad:byte):string;
const
  ARazrjad: array [2..9] of string =('двадцать','тридцать','сорок','пятьдесят','шестьдесят','семьдесят','восемьдесят','девяносто');
begin
  Result:=BLANK+ARazrjad[Razrjad];
end;

function Edinici(Razrjad:byte;IsM:boolean):string;
const
  ARazrjad: array [1..19] of string = ('один','два','три','четыре','пять','шесть','семь','восемь','девять','десять','одинадцать','двенадцать',
                                       'тринадцать','четырнадцать','пятнадцать','шестнадцать','семнадцать','восемнадцать','девятнадцать');
begin
  case Razrjad of
  1: if IsM  then
       Result:=BLANK+ARazrjad[Razrjad]
     else
       Result:=' одна';
  2: if IsM  then
       Result:=BLANK+ARazrjad[Razrjad]
     else
       Result:=' две'
  else
    Result:=BLANK+ARazrjad[Razrjad];
  end;//case
end;

function Millioni(Razrjad:byte):string;
begin
  if Razrjad = 1 then
    Result:=' миллион';
  if (Razrjad > 1) and (Razrjad < 5) then
    Result:=' миллиона';
  if Razrjad > 4 then
    Result:=' миллионов';
end;

function Sotni (Razrjad:byte):string;
const
  ARazrjad: array [1..9] of string = ('сто','двести','триста','четыреста','пятьсот','шестьсот','семьсот','восемьсот','девятьсот');
begin
  Result:=BLANK+ARazrjad[Razrjad];
end;

function Tisachi(Razrjad:byte):string;
begin
  if Razrjad = 1 then
    Result:=' тысяча';
  if (Razrjad > 1) and (Razrjad < 5) then
    Result:=' тысячи';
  if Razrjad > 4 then
    Result:=' тысяч';
  if Razrjad = 0 then
    Result:=' тысяч';
end;

function Rubli(Razrjad:byte):string;
begin
  if Razrjad = 0 then
    Result:=' рублей ';
  if Razrjad = 1 then
    Result:=' рубль ';
  if (Razrjad > 1) and (Razrjad < 5) then
    Result:=' рубля ';
  if Razrjad > 4 then
    Result:=' рублей ';
end;

function GruppCount(var Gruppa,Ostatok:longint;const Deldiv:longint;var Razrjad:byte):string;
begin
  Gruppa:=Ostatok div Deldiv;
  Ostatok:=Ostatok mod Deldiv;
  if Gruppa <> 0 then
    begin
      Razrjad:=Gruppa div 100;
      if Razrjad <> 0 then
        Result:=Result+Sotni(Razrjad);
      Gruppa:=Gruppa-Razrjad*100;
      if Gruppa > 19 then
        begin
          Razrjad:=Gruppa div 10;
          if Razrjad <> 0 then
            Result:=Result+Desjatki(Razrjad);
          Gruppa:=Gruppa-Razrjad*10;
        end;
      Razrjad:=Gruppa;
      if Razrjad <> 0 then
        if Deldiv = 1000 then
          Result:=Result+Edinici(Razrjad,False)
        else
          Result:=Result+Edinici(Razrjad,True);
    end;
end;

var
  Gruppa,Ostatok:longInt;
  n:longint = 1000000;
  Razrjad:byte = 0;
begin
  Ostatok:=Trunc(SummaSch);
  while n > 0 do
    begin
      Result:=Result+GruppCount(Gruppa,Ostatok,n,Razrjad);
      case n of
      1000000:begin
                if Razrjad <> 0 then
                  Result:=Result+Millioni(Razrjad);
              end;
         1000:begin
                if Razrjad <> 0 then
                  Result:=Result+Tisachi(Razrjad);
              end;
      end; //case
      n:=n div 1000;
    end;
  if Result='' then
    Result:=' ноль';
  if Rub then
    Result:=WordUpperCase(Result+Rubli(Razrjad))
  else
    Result:=WordUpperCase(Result);
  if Kop then
    Result:=Result+BLANK+KopToStr(SummaSch,True);
end;



//Функция написания слова копейка в различных падежах
function Kopejki(const Kop:string):string;
begin
  if Kop[1]='1' then
  begin
     case Kop[2] of
     '0'..'9':Result:=' копеек';
     end;
  Exit;
  end;
  case Kop[2] of
  '0':Result:=' копеек';
  '1':Result:=' копейка';
  '2'..'4':Result:=' копейки';
  '5'..'9':Result:=' копеек';
  end;
end;



//Функция преобразования копеек(в Currency) в строку(String)
//Kopstr = True - добавляет слово 'копеек'
function KopToStr(M:Currency;Kopstr:boolean = False):string;
begin
  Result:=FloatToStrF(Frac(M),ffFixed,1,2);
  Delete(Result,1,2);
  if Kopstr then Result:=Result+Kopejki(Result);
end;



//процедура разбивки фамилии на фамилию, имя, отчество (при ФИО одной строкой)
//возвращает в переменных Fam, Name, Otch - раздельно фамилию, имя, отчество
procedure BreakFIO(const FIO:string;var Fam,Name,Otch:string);
var
nompos:integer;
AFIO:string;
begin
  nompos:=UTF8Pos(' ',FIO);
  if nompos = 0 then
    begin
      Fam:=FIO;
      Exit;
    end;
  Fam:=UTF8Copy(FIO,0,nompos-1);
  AFIO:=FIO;
  UTF8Delete(AFIO,0,nompos);
  nompos:=UTF8Pos(' ',AFIO);
  if nompos = 0 then
    begin
      Name:=AFIO;
      Exit;
    end;
  Name:=UTF8Copy(AFIO,0,nompos-1);
  UTF8Delete(AFIO,0,nompos);
  Otch:=AFIO;
end;


//stroka - разбиваемая строка
//KolZnakov - количество знаков в первой строке (строка делится по пробелам)
//stroka2 - остаток строки после разбивки
//функция разбивки строки stroka на две (для переносов текста в отчетах)
function StrokaRazbivka(const stroka:string;var stroka2:string;KolZnakov:integer = 32):string;
var
  k:integer;
begin
  if UTF8Length(stroka) <= KolZnakov then
    begin
      Result:=stroka;
      Exit;
    end;
  if GetChar(stroka,KolZnakov) <> BLANK then
    for k:=KolZnakov downto 1 do
      if GetChar(stroka,k) = BLANK then
        begin
          Result:=UTF8Copy(stroka,1,k-1);
          stroka2:=UTF8Copy(stroka,k+1,UTF8Length(stroka)-k+1);
          Exit;
        end;
  Result:=UTF8Copy(stroka,1,KolZnakov);
  stroka2:=UTF8Copy(stroka,KolZnakov+1,UTF8Length(stroka)-KolZnakov+1);
end;


end.

