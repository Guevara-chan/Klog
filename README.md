# :.Sum.:
__Klog__ was a research project to make distributed client/server PC activity monitoring system.  
Powered silmulatenously by .NET and native code, it is designed around mailbox data sharing.  
❗ Due to data protection laws, __no actual releases is gonna be provided here__. ❗

# :.Opticum.:
__Design:__ Low-rofile keyboard, clip and screen logger, developed entirelly in [PureBasic v5.60 LTS](https://www.purebasic.com/)  
__Usage:__ recording and sending log fragments to pre-defined email address.  
__Extra:__ may have troubles with future compiler versions due to `SMTP` lib regressions.  

# :.Demagnifier.:
__Design:__ mass message-retriever, implemented in pure [Boo v0.9.7.0](https://github.com/boo-lang/boo).  
__Usage:__ gathering and sorting __Opticum__ log fragments from pre-defined email address to local storage.  
__Extra:__ requires .NET 4.0 framework to run. Confirmed as being mostly compatible with [Mono 4.6.2+](https://github.com/mono/mono).

# :.Re-port.:
__Design:__ __Opticum__ log reconverter and beatifier, written in [PureBasic v5.60 LTS](https://www.purebasic.com/)  
__Usage:__ merging selected subsection of __Demagnifier__-provided data scraps into single HTML report.  
__Extra:__ requires [Chromium](https://github.com/chromium/chromium)-based browser to properly render resulting document.  

# :.Brief sampling of observation results.:
![image](https://user-images.githubusercontent.com/8768470/59960399-865f1f00-94d0-11e9-990a-640ac58411d7.png)
