class Config:
    BaseURL = "https://www.syntax.eco"
    AuthorizationToken = "ExampleAuthToken"
    CommPort = 3000
    RCCServicePath = "./RCCService/RCCService.exe"
    RCCService2018Path = "./RCCService2018/RCCService.exe"
    RCCService2020Path = "./RCCService2020/RCCService.exe"
    Client2014Path = "./Player2014/SyntaxPlayerBeta.exe"
    RCCService2021Path = "./RCCService2021/RCCService.exe"
    RCCStartingPort = 53640
    RCCEndingPort = 53900
    RCCStartingComPort = 64989
    RCCEndingComPort = 65200
    ThumbnailWorkerCount = 2
    PortOffset = 400 # Offset for ports so it will be ActualPort + PortOffset = Gameserver Running Port