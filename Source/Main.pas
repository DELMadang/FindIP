unit Main;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Winsock,
  Winapi.Winsock2,
  Winapi.Windows,
  Winapi.IpHlpApi,
  Winapi.IpTypes,

  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Forms;

type
  PIPAddressInfo = ^TIPAddressInfo;
  TIPAddressInfo = record
    IPAddress: string;
    AddressFamily: string;
    InterfaceName: string;
    InterfaceIndex: Cardinal;
    PrefixLength: Cardinal;
    IPType: string;
  end;

  TIPAddressArray = array of TIPAddressInfo;

  TFormIPFinder = class(TForm)
    ButtonFindIPs: TButton;
    MemoResults: TMemo;
    procedure ButtonFindIPsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function GetAllIPAddresses: TIPAddressArray;
    function GetIPType(const IPAddress: string): string;
  public
    { Public declarations }
  end;

var
  FormIPFinder: TFormIPFinder;

implementation

{$R *.dfm}

function TFormIPFinder.GetIPType(const IPAddress: string): string;
begin
  if (Pos('127.', IPAddress) = 1) or (IPAddress = '::1') then
    Result := '루프백'
  else if Pos('169.254.', IPAddress) = 1 then
    Result := 'APIPA'
  else if Pos('fe80::', IPAddress) = 1 then
    Result := '링크-로컬'
  else
    Result := '일반';
end;

function TFormIPFinder.GetAllIPAddresses: TIPAddressArray;
var
  AdapterAddresses: PIP_ADAPTER_ADDRESSES;
  AdapterAddress: PIP_ADAPTER_ADDRESSES;
  UnicastAddress: PIP_ADAPTER_UNICAST_ADDRESS;
  SockAddr: PSOCKADDR;
  Ipv4Address: PIN_ADDR;
//  Ipv6Address: PIN6_ADDR;
  IPAddress: string;
  BufferSize, RetVal: ULONG;
  Family: Integer;
  IPType: string;
  i: Integer;
begin
  // 초기 버퍼 크기 설정
  BufferSize := 15000;
  Result := nil;
  
  GetMem(AdapterAddresses, BufferSize);
  try
    // 어댑터 정보 가져오기 시도
    RetVal := GetAdaptersAddresses(AF_UNSPEC, GAA_FLAG_INCLUDE_PREFIX, nil, AdapterAddresses, @BufferSize);

    if RetVal = ERROR_BUFFER_OVERFLOW then
    begin
      // 버퍼가 충분하지 않으면 다시 할당
      FreeMem(AdapterAddresses);
      BufferSize := BufferSize * 2;
      GetMem(AdapterAddresses, BufferSize);
      RetVal := GetAdaptersAddresses(AF_UNSPEC, GAA_FLAG_INCLUDE_PREFIX, nil, AdapterAddresses, @BufferSize);
    end;

    if RetVal = ERROR_SUCCESS then
    begin
      // 초기 주소 개수 계산
      i := 0;
      AdapterAddress := AdapterAddresses;
      while Assigned(AdapterAddress) do
      begin
        UnicastAddress := AdapterAddress^.FirstUnicastAddress;
        while Assigned(UnicastAddress) do
        begin
          Inc(i);
          UnicastAddress := UnicastAddress^.Next;
        end;
        AdapterAddress := AdapterAddress^.Next;
      end;

      // 결과 배열 초기화
      SetLength(Result, i);
      i := 0;

      // 각 어댑터와 IP 정보 처리
      AdapterAddress := AdapterAddresses;
      while Assigned(AdapterAddress) do
      begin
        UnicastAddress := AdapterAddress^.FirstUnicastAddress;
        while Assigned(UnicastAddress) do
        begin
          SockAddr := UnicastAddress^.Address.lpSockaddr;
          Family := SockAddr^.sa_family;

          if Family = AF_INET then // IPv4
          begin
            Ipv4Address := @PSockAddrIn(SockAddr)^.sin_addr;
            SetLength(IPAddress, 16);
            inet_ntop(AF_INET, Ipv4Address, PAnsiChar(IPAddress), 16);
            IPAddress := string(PAnsiChar(IPAddress));
            Result[i].AddressFamily := 'IPv4';
          end
          else if Family = AF_INET6 then // IPv6
          begin
//            Ipv4Address := @PSockAddrIn6(SockAddr)^.sin6_addr;
//            SetLength(IPAddress, 46);
//            inet_ntop(AF_INET6, Ipv6Address, PAnsiChar(IPAddress), 46);
//            IPAddress := string(PAnsiChar(IPAddress));
//            Result[i].AddressFamily := 'IPv6';
          end
          else
          begin
            IPAddress := '알 수 없는 주소 유형';
            Result[i].AddressFamily := '알 수 없음';
          end;

          // IP 주소 정보 저장
          Result[i].IPAddress := IPAddress;
          Result[i].InterfaceName := string(PWideChar(AdapterAddress^.FriendlyName));
          Result[i].InterfaceIndex := AdapterAddress^.Ipv6IfIndex;
          Result[i].PrefixLength := UnicastAddress^.OnLinkPrefixLength;
          Result[i].IPType := GetIPType(IPAddress);

          Inc(i);
          UnicastAddress := UnicastAddress^.Next;
        end;
        AdapterAddress := AdapterAddress^.Next;
      end;

      // 실제 사용한 배열 크기로 조정
      if i < Length(Result) then
        SetLength(Result, i);
    end;
  finally
    FreeMem(AdapterAddresses);
  end;
end;

procedure TFormIPFinder.ButtonFindIPsClick(Sender: TObject);
var
  IPAddresses: TIPAddressArray;
  i, IPv4Count, IPv6Count: Integer;
  Results: TStringList;
begin
  MemoResults.Clear;
  MemoResults.Lines.Add('컴퓨터의 모든 IP 주소를 검색 중...');
  MemoResults.Lines.Add('');
  
  Screen.Cursor := crHourGlass;
  try
    IPAddresses := GetAllIPAddresses;
    
    // 결과 정렬 및 출력을 위한 문자열 리스트 생성
    Results := TStringList.Create;
    try
      Results.Add('IP 주소' + #9 + '유형' + #9 + '주소 종류' + #9 + '인터페이스' + #9 + '인덱스' + #9 + '프리픽스 길이');
      Results.Add('----------------------------------------------------------------------------------------------------------------');

      // IPv4 주소 먼저 표시
      IPv4Count := 0;
      IPv6Count := 0;
      
      // IPv4 주소 먼저 출력
      for i := 0 to Length(IPAddresses) - 1 do
      begin
        if IPAddresses[i].AddressFamily = 'IPv4' then
        begin
          Results.Add(
            IPAddresses[i].IPAddress + #9 +
            IPAddresses[i].IPType + #9 +
            IPAddresses[i].AddressFamily + #9 +
            IPAddresses[i].InterfaceName + #9 +
            IntToStr(IPAddresses[i].InterfaceIndex) + #9 +
            IntToStr(IPAddresses[i].PrefixLength)
          );
          Inc(IPv4Count);
        end;
      end;

      // 구분선 추가
      Results.Add('----------------------------------------------------------------------------------------------------------------');
      
      // IPv6 주소 출력
      for i := 0 to Length(IPAddresses) - 1 do
      begin
        if IPAddresses[i].AddressFamily = 'IPv6' then
        begin
          Results.Add(
            IPAddresses[i].IPAddress + #9 +
            IPAddresses[i].IPType + #9 +
            IPAddresses[i].AddressFamily + #9 +
            IPAddresses[i].InterfaceName + #9 +
            IntToStr(IPAddresses[i].InterfaceIndex) + #9 +
            IntToStr(IPAddresses[i].PrefixLength)
          );
          Inc(IPv6Count);
        end;
      end;
      
      // 요약 정보 추가
      Results.Add('');
      Results.Add('----------------------------------------------------------------------------------------------------------------');
      Results.Add('요약:');
      Results.Add('IPv4 주소 개수: ' + IntToStr(IPv4Count));
      Results.Add('IPv6 주소 개수: ' + IntToStr(IPv6Count));
      Results.Add('총 IP 주소 개수: ' + IntToStr(IPv4Count + IPv6Count));
      
      // 결과 표시
      MemoResults.Lines := Results;
    finally
      Results.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormIPFinder.FormCreate(Sender: TObject);
begin
  MemoResults.Clear;
  MemoResults.Lines.Add('IP 주소 검색 도구');
  MemoResults.Lines.Add('');
  MemoResults.Lines.Add('시작하려면 "IP 주소 찾기" 버튼을 클릭하세요.');
end;

end.
