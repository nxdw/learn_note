
Nginx：
	
	engine X = Nginx
	
		http协议：web服务器（类似于httpd）、http reverse proxy（类似于httpd）、imap/pop3 reverse proxy
			
		NGINX is a free, open-source, high-performance HTTP server and reverse proxy, as well as an IMAP/POP3 proxy server. 
		
		C10K（10K Connections）.
		Tengine, OpenResty.
		
	http协议:
		URL：shceme://username:password@host:port/path;params?query#frag
		
		http事务：
			request：
				<method> <URL> <VERSION>
				HEADERS
				
				<body>
			
			response：
				<VERSION> <STATUS> <REASON-PHRASE>
				HEADERS
				
				<body>
		
			Method：GET/HEAD/POST, PUT/DELETE, TRACES, OPTIONS
		
			Status Code：
				1xx：
				2xx：成功类响应码，200
				3xx：重定向类的响应码，301, 302, 304
				4xx：客户端错误，403，404
				5xx：服务器端错误，502
				
			认证：
				基于ip认证
				基于用户认证 ：basic/digest
				
			httpd MPM：
				prefork：进程模型，两级结构，主进程master负责生成子进程，每个子进程负责响应一个请求；
				worker：线程模型，三级结构，主进程master负责生成子进程，每个子进程负责生成多个线程，每个线程响应一个请求；
				event：主进程master负责生成子进程，每个子进程响应多个请求；有一个监控线程，如果有线程处于停止状态，就会被收回，防止占用资源。
                event、worker：一个线程出问题会影响同一个进程中的其它线程，所以event和worker的稳定性不如prefork
				
	I/O模型：
		阻塞型、非阻塞型、复用型、信号驱动型、异步
		
		同步/异步：
			关注消息通知机制；
			
			消息通知：
				同步：等待对方返回消息； 
				异步：被调用者通过状态、通知或回调机制通知调用者被调用者的运行状态；
		
		阻塞/非阻塞：
			关注调用者在等待结果返回之前所处的状态； 
			
				阻塞：blocking，调用结果返回之前，调用者被挂起；
				非阻塞：nonblocking，调用结果返回之前，调用者不会被挂起；
				
		一次IO请求，都会由两阶段组成：
			第一步：等待数据，即数据从磁盘到内核内存； 
			第二步：复制数据，即数据内核内存到进程内存；

        同步阻塞I/O模型：
            应用程序向内核发起系统调用后，需要等内核把应用程序所需的资源完全读取到用户空间对应应用程序的内存中，应用程序才开始工作，在内核读取资源的这个过程中应用程序是一直处于等待状态的。
			
        同步非阻塞I/O模型：
            应用程序向内核发起系统调用后，在内核把磁盘中所需文件复制到内核内存的这段时间，应用程序需要不断的询问内核的执行状态，待内核把文件读取到内核内存之后，应用程序就不再询问。在这期间，应用程序可以执别的指令，但需要不断的询问内核的执行情况。
        
        IO多路复用模型：
            内核为应用程序提供一个select功能，应用程序把系统调用交给select，由select代理应用程序去访问内核。当内核把文件从磁盘读取到内核内存之后，由select通知应用程序。select可以应对多个应用程序进程，所以称为多路复用。应用程序阻塞于select。

        信号驱动IO模型：
            应用程序通过发送信号的方式去调用内核，在内核把资源从磁盘读取到内核内存之前应用程序可以处理受别的请求。
        
        异步IO模型：
            应用程序系统调用内核，内核把文件读取到内核内存再到应用程序内存，再通知应用程序，整个内核读取文件的过程中应用程序都可以接受别的请求，而不用阻塞。

        主要实现方式有以下几种：
            Select：Linux实现对应，I/O复用模型，BSD4.2最早实现
            Poll：Linux实现，对应I/O复用模型，System V unix最早实现
            Epoll：Linux实现，对应I/O复用模型，具有信号驱动I/O模型的某些特性
            Kqueue：FreeBSD实现，对应I/O复用模型，具有信号驱动I/O模型某些特性
            /dev/poll：SUN的Solaris实现，对应I/O复用模型，具有信号驱动I/O模型的某些特性
            Iocp Windows实现，对应第5种（异步I/O）模型


        Select:
            POSIX所规定，目前几乎在所有的平台上支持，其良好跨平台支持也是它的一个优点，本质上是通过设置或者检查存放fd标志位的数据结构来进行下一步处理
            缺点
            单个进程可监视的fd数量被限制，即能监听端口的数量有限
                cat /proc/sys/fs/file-max 
            对socket是线性扫描，即采用轮询的方法，效率较低
            select 采取了内存拷贝方法来实现内核将 FD 消息通知给用户空间，这样一个用来存放大量fd的数据结构，这样会使得用户空间和内核空间在传递该结构时复制开销大

        poll
            本质上和select没有区别，它将用户传入的数组拷贝到内核空间，然后查询每个fd对应的设备状态
            其没有最大连接数的限制，原因是它是基于链表来存储的
            大量的fd的数组被整体复制于用户态和内核地址空间之间，而不管这样的复制是不是有意义
            poll特点是“水平触发”，如果报告了fd后，没有被处理，那么下次poll时会再次报告该fd
            边缘触发：只通知一次

        epoll：
            在Linux 2.6内核中提出的select和poll的增强版本
            支持水平触发LT和边缘触发ET，最大的特点在于边缘触发，它只告诉进程哪些fd刚刚变为就需态，并且只会通知一次
            使用“事件”的就绪通知方式，通过epoll_ctl注册fd，一旦该fd就绪，内核就会采用类似callback的回调机制来激活该fd，epoll_wait便可以收到通知
            优点:
            没有最大并发连接的限制：能打开的FD的上限远大于1024(1G的内存能监听约10万个端口)
            效率提升：非轮询的方式，不会随着FD数目的增加而效率下降；只有活跃可用的FD才会调用callback函数，即epoll最大的优点就在于它只管理“活跃”的连接，而跟连接总数无关
            内存拷贝，利用mmap(Memory Mapping)加速与内核空间的消息传递；即epoll使用mmap减少复制开销
            
		复用型IO调用：
			select()：1024 
			poll()：
			
			event-driven：
				epoll（Linux）：libevent
				Kqueue（BSD）：
				Solaris：/dev/poll
				
	NGINX is a free, open-source, high-performance HTTP server and reverse proxy, as well as an IMAP/POP3 proxy server. NGINX is known for its high performance, stability, rich feature set, simple configuration, and low resource consumption.

	NGINX is one of a handful of servers written to address the C10K problem. Unlike traditional servers, NGINX doesn’t rely on threads to handle requests. Instead it uses a much more scalable event-driven (asynchronous) architecture. This architecture uses small, but more importantly, predictable amounts of memory under load. Even if you don’t expect to handle thousands of simultaneous requests, you can still benefit from NGINX’s high-performance and small memory footprint. NGINX scales in all directions: from the smallest VPS all the way up to large clusters of servers.

	NGINX powers several high-visibility sites, such as Netflix, Hulu, Pinterest, CloudFlare, Airbnb, WordPress.com, GitHub, SoundCloud, Zynga, Eventbrite, Zappos, Media Temple, Heroku, RightScale, Engine Yard, MaxCDN and many others.		
			
	Nginx的程序架构：
		master/worker
			一个master进程：
				负载加载和分析配置文件、管理worker进程、平滑升级
			一个或多个worker进程
				处理并响应用户请求
			缓存相关的进程：
				cache loader：载入缓存对象
				cache manager：管理缓存对象
				
		特性：异步、事件驱动和非阻塞
			并发请求处理：通过kevent/epoll/select，/dev/poll
			文件IO：高级IO sendfile，异步，mmap
			
		nginx高度模块：高度模块化，但其模块早期不支持DSO机制；近期版本支持动态装载和卸载；
			模块分类：
				核心模块：core module,必须有的，基本模块
				标准模块：
					HTTP modules：
						Standard HTTP modules
						Optional HTTP modules
					Mail modules
					Stream modules
				第三方模块 party modules
				
		nginx的功用：
			静态的web资源服务器；(图片服务器，或js/css/html/txt等静态资源服务器)
			结合FastCGI/uwSGI/SCGI等协议反代动态资源请求；
			http/https协议的反向代理；
			imap4/pop3协议的反向代理；
			tcp/udp协议的请求转发；
			
	nginx的安装配置：
		官方的预制包：
			http://nginx.org/packages/centos/7/x86_64/RPMS/
			Fedora-EPEL:
		
		编译安装：
			 yum install pcre-devel openssl-devel zlib-devel
			 useradd -r nginx
		    ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=nginx --group=nginx --with-http_ssl_module --with-http_v2_module --with-http_dav_module --with-http_stub_status_module --with-threads --with-file-aio
			# make && make install
			
		配置：
			配置文件的组成部分：
				主配置文件：nginx.conf
					include conf.d/*.conf
				fastcgi， uwsgi，scgi等协议相关的配置文件
				mime.types：支持的mime类型
				
			主配置文件的配置指令：
				directive value [value2 ...];
				
				注意：
					(1) 指令必须以分号结尾；
					(2) 支持使用配置变量；
						内建变量：由Nginx模块引入，可直接引用；
						自定义变量：由用户使用set命令定义；
							set variable_name value;
							引用变量：$variable_name
							
			主配置文件结构：
				main block：主配置段，也即全局配置段；
					event {
						...
					}：事件驱动相关的配置；
				http {
					...
				}：http/https 协议相关的配置段；
				mail {
					...
				}
				stream {
					...
				}
			
			http协议相关的配置结构
				http {
					...
					...：各server的公共配置
					server {
						...
					}：每个server用于定义一个虚拟主机；
					server {
						...
						server_name
						root
						alias
						location [OPERATOR] URL {
							...
							if CONDITION {
								...
							}
						}
					}
				}
				
			nginx命令

				nginx 启动nginx，不需要通过systemd
				nginx -h  显示nginx的使用帮助
				nginx -V  显示nginx编译时的选项
				nginx -s stop，quit，reopen，reload  停止，退出，重新加载
			
		
			main配置段常见的配置指令：
				分类：
					正常运行必备的配置
					优化性能相关的配置
					用于调试及定位问题相关的配置
					事件驱动相关的配置
					
				正常 运行必备的配置：
					1、user   指定nginx以什么身份运行
						Syntax:	user user [group];
						Default:	user nobody nobody; 
						Context:	main
						
						Defines user and group credentials used by worker processes. If group is omitted, a group whose name equals that of user is used.
						
					2、pid /PATH/TO/PID_FILE;  
						指定存储nginx主进程进程号码的文件路径；
						
					3、include file | mask;
						指明包含进来的其它配置文件片断；
						
					4、load_module file;
						指明要装载的动态模块；
                    
                    注：部分指令必须放在对应的语句块，不能随意放
						
				性能优化相关的配置：
					1、worker_processes number | auto;
						worker进程的数量；通常应该为当前主机的cpu的物理核心数；
						
					2、worker_cpu_affinity cpumask ...; 绑定cpu和nginx进程，充分利用cpu缓存，不用再cpu之间来回切换
						worker_cpu_affinity auto [cpumask];
						
						CPU MASK：
							00000001：0号CPU
							00000010：1号CPU 
							... ...
					3、worker_priority number;
						指定worker进程的nice值，设定worker进程优先级；[-20,20]，nice越小，优先级越高
						
					4、worker_rlimit_nofile number;
						worker进程所能够打开的文件数量上限；socket文件数，进程的并发连接数
						
				调试、定位问题：
					1、daemon on|off;	
						是否以守护进程方式运行Nignx；前台、后台
						
					2、master_process on|off;
						是否以master/worker模型运行nginx；默认为on；是否开启子进程
						
					3、error_log file [level]; 日志存放路径及其日志级别
						错误日志文件及其级别；出于调试需要，可设定为debug；但debug仅在编译时使用了“--with-debug”选项时才有效
						方式：file /path/logfile;
						stderr:发送到标准错误
						syslog:server-address[,parameter=values]:  发送到syslog memory:size 内存
						level:debug|info|notice|warn|error|crit|alter|emerg 日志级别

				事件驱动相关的配置:
					events {
						...
					}
					
					1、worker_connections number;
						每个worker进程所能够打开的最大并发连接数数量；
						
						worker_processes * worker_connections
						
					2、use method;
						指明并发连接请求的处理方法；
							
							use epoll;
							
					3、accept_mutex on | off;
						处理新的连接请求的方法；on意味着由各worker轮流处理新请求，Off意味着每个新请求的到达都会通知所有的worker进程，但只有一个进程可获得连接，但唤醒了所有进程会导致系统资源消耗。
						
回顾：IO模型、nginx

	IO模型：
		阻塞式
		非阻塞式
		复用型IO (select, poll)
		事件驱动型IO （epoll，Kqueue, /dev/poll）
		AIO 
		
		IO阶段：等待数据准备完成（从磁盘到内核内存）、复制（从内核内存至进程内存）
		mmap：
		
	nginx：master/worker
		master：配置文件、worker、平滑升级；
		worker：处理用户请求；
		cache loader, cache manager
		
		高度模块化：
			HTTP module
				Standard HTTP Module
				Optional HTTP Module
			Mail Module
			Stream Module
						
		nginx.conf
			main block
				event {
					...
				}
			http {
				...
			}
			mail {
				...
			}
			stream {
				...
			}
			
			http {
				...
				server {
					...
				}
				server {
					...
					server_name
					root
					location /uri/ {
						...
						if CONDITION {
							...
						}
					}
				}
			}
			
Nginx（2）
	
	Nginx配置：
			http协议的相关配置：
				http {
					... ...
					server {
						...
						server_name     
						root
						location [OPERATOR] /uri/ {
							...
						}
					}
					server {
						...
					}
				}
				
				与套接字相关的配置：
				
					1、server { ... }
						配置一个虚拟主机；
							
						server {
							listen address[:PORT]|PORT;
							server_name SERVER_NAME;
							root /PATH/TO/DOCUMENT_ROOT;
						}
                        服务器根据http请求报文头部的fqdn来区分不同fqdn的虚拟主机
						
					2、listen PORT|address[:port]|unix:/PATH/TO/SOCKET_FILE
					      listen address[:port] [default_server] [ssl] [http2 | spdy]  [backlog=number] [rcvbuf=size] [sndbuf=size]
						
						default_server：设定为默认虚拟主机；
						ssl：限制仅能够通过ssl连接提供服务；
						backlog=number：后援队列长度；
						rcvbuf=size：接收缓冲区大小；
						sndbuf=size：发送缓冲区大小；
						注意：
						(1) 基于port；
							listen PORT; 指令监听在不同的端口
						(2) 基于ip的虚拟主机
							listen IP:PORT; IP 地址不同
						(3) 基于hostname
							server_name fqdn; 指令指向不同的主机名
						
					3、server_name name ...;
						指明虚拟主机的主机名称；后可跟多个由空白字符分隔的字符串；
							支持*通配任意长度的任意字符；server_name *.zhanghw.com  www.zhanghw.*
							支持~起始的字符做正则表达式模式匹配；server_name ~^www\d+\.zhanghw\.com$
							
						匹配机制：
							(1) 首先是字符串精确匹配;
							(2) 左侧*通配符；
							(3) 右侧*通配符；
							(4) 正则表达式；
					
						
					4、tcp_nodelay on | off;
						在keepalived模式下的连接是否启用TCP_NODELAY选项；
                        off，延迟发送，多个请求合并后发送
                        on，不延迟发送
						
					5、sendfile on | off;
						是否启用sendfile功能；在内核中封装报文直接发送，默认off

                    server_tokens on | off | build | string
                        是否在响应报文的Server首部显示nginx版本
						
				定义路径相关的配置：
					6、root path; 
						设置web资源路径映射；用于指明用户请求的url所对应的本地文件系统上的文档所在目录路径；可用的位置：http, server, location, if in location；
						
					7、location [ = | ~ | ~* | ^~ ] uri { ... }
						location @name { ... }
						
						在一个server中location配置段可存在多个，用于实现从uri到文件系统的路径映射；ngnix会根据用户请求的URI来检查定义的所有location，并找出一个最佳匹配，而后应用其配置；
						
						=：对URI做精确匹配；例如, http://www.zhanghw.com/, http://www.zhanghw.com/index.html
							location = / {
								...
							}
						~：对URI做正则表达式模式匹配，区分字符大小写；
						~*：对URI做正则表达式模式匹配，不区分字符大小写；
						^~：对URI的左半部分做匹配检查，不区分字符大小写；  实现动静分离
						不带符号：匹配起始于此uri的所有的url；
						
						匹配优先级：=, ^~, ～/～*，不带符号；
						= 有问题
						
						root /vhosts/www/htdocs/
							http://www.zhanghw.com/index.html --> /vhosts/www/htdocs/index.html
							
						server {
							root  /vhosts/www/htdocs/
							
							location /admin/ {
								root /webapps/app1/data/
							}
						}
						http://www.zhanghw.com/admin/index.html --> /webapps/app1/data/admin/index.html
						
					8、alias path;
						定义路径别名，文档映射的另一种机制；仅能用于location上下文；
						
						注意：location中使用root指令和alias指令的意义不同；
							(a) root，给定的路径对应于location中的/uri/左侧的/；
							(b) alias，给定的路径对应于location中的/uri/右侧的/；

							location /i/ {
										alias   /data/web2/;
										}   
							注：如果location后面的URI有/，则alias后面的路径也得有/

							
					9、index file ...;

						默认资源；http, server, location；指定默认网页文件
						
					10、error_page code ... [=[response]] uri;
						Defines the URI that will be shown for the specified errors. 
                        定义错误页面，如果访问错误，不返回404，而是返回一个自定义的页面。
						error_page 404 /404.html
						error_page 404 =200 /404.html

					11、try_files file ... uri;
					按顺序检查文件是否存在，返回第一个找到的文件或文件夹（结尾加斜线表示为文件夹），如果所有的文件或文件夹都找不到，会进行一个内部重定向到最后一个参数。只有最后一个参数可以引起一个内部重定向，之前的参数只设置内部URI的指向。最后一个参数是回退URI且必须存在，否则会出现内部500错误
						location /images/ { 
						try_files $uri /images/default.gif; 
						}
						location / { 
						try_files $uri $uri/index.html $uri.html =404; 
						}
				
					12、keepalive_timeout timeout [header_timeout];
						设定保持连接的超时时长，0表示禁止长连接；默认为75s；
						
					13、keepalive_requests number;
						在一次长连接上所允许请求的资源的最大数量，默认为100; 
						
					14、keepalive_disable none | browser ...;
						对哪种浏览器禁用长连接；
						
					15、send_timeout time;
						向客户端发送响应报文的超时时长，此处，是指两次写操作之间的间隔时长；
						
					16、client_body_buffer_size size;
						用于接收客户端请求报文的body部分的缓冲区大小；默认为16k；超出此大小时，其将被暂存到磁盘上的由client_body_temp_path指令所定义的位置；
						
					17、client_body_temp_path path [level1 [level2 [level3]]];
						设定用于存储客户端请求报文的body部分的临时存储路径及子目录结构和数量；
						
							16进制的数字；
							
							client_body_temp_path path  /var/tmp/client_body  1 2 2
							1 1级目录占1位16进制，即2^4=16个目录 0-f
							2 2级目录占2位16进制，即2^8=256个目录 00-ff
							2 3级目录占2位16进制，即2^8=256个目录 00-ff
							
				对客户端进行限制的相关配置：
					18、limit_rate rate;
						限制响应给客户端的传输速率，单位是bytes/second，默认0表示无限制；
						
					19、limit_except method ... { ... }
						限制对指定的请求方法之外的其它方法的使用客户端；仅能用于location
						
						limit_except GET {
                        
							allow 192.168.1.0/24;
							deny  all;
						}			 			
						
				 文件操作优化的配置
					20、aio on | off | threads[=pool];
						是否启用aio功能；aio：异步IO
						
					21、directio size | off;
						在Linux主机启用O_DIRECT标记，此处意味文件大于等于给定的大小时使用，例如directio 4m;
						
					22、open_file_cache off; 是否支持缓存
						open_file_cache max=N [inactive=time];
							nginx可以缓存以下三种信息：
								(1) 文件元数据：文件的描述符、文件大小和最近一次的修改时间；
								(2) 打开的目录结构；
								(3) 没有找到的或者没有权限访问的文件的相关信息；
							
							max=N：可缓存的缓存项上限；达到上限后会使用LRU算法实现缓存管理；
													
							inactive=time：缓存项的非活动时长，在此处指定的时长内未被命中的或命中的次数少于open_file_cache_min_uses指令所指定的次数的缓存项即为非活动项；
							
					23、open_file_cache_valid time;
						缓存项有效性的检查频率；
						默认为60s; 
						
					24、open_file_cache_min_uses number;
						在open_file_cache指令的inactive参数指定的时长内，至少应该被命中多少次方可被归类为活动项；
						
					25、open_file_cache_errors on | off;
						是否缓存查找时发生错误的文件一类的信息；
						默认值为off
						
				ngx_http_access_module模块：
					实现基于ip的访问控制功能
					
					26、allow address | CIDR | unix: | all;
					27、deny address | CIDR | unix: | all;
					
						http, server, location, limit_except
						
				ngx_http_auth_basic_module模块
					实现基于用户的访问控制，使用basic机制进行用户认证；
					
					28、auth_basic string | off;
					29、auth_basic_user_file file;
					
						location /admin/ {  
							alias /webapps/app1/data/;  
							auth_basic "Admin Area";  
							auth_basic_user_file /etc/nginx/.ngxpasswd; 
						}
						
						注意：htpasswd命令由httpd-tools所提供；
						
				ngx_http_stub_status_module模块 
					用于输出nginx的基本状态信息；
					
					Active connections: 291 
					server accepts handled requests
						16630948 16630948 31070465 
					Reading: 6 Writing: 179 Waiting: 106 	
					
					Active connections: 活动状态的连接数；
					accepts：已经接受的客户端请求的总数；
					handled：已经处理完成的客户端请求的总数；
					requests：客户端发来的总的请求数；
					Reading：处于读取客户端请求报文首部的连接的连接数；
					Writing：处于向客户端发送响应报文过程中的连接数；
					Waiting：处于等待客户端发出请求的空闲连接数；
					
					30、stub_status;
					
					配置示例：
						location  /basic_status {
							stub_status;
						}
						
				ngx_http_log_module模块
					he ngx_http_log_module module writes request logs in the specified format.
					
					31、log_format name string ...;
						string可以使用nginx核心模块及其它模块内嵌的变量；
						
						
					32、access_log path [format [buffer=size] [gzip[=level]] [flush=time] [if=condition]];
						access_log off; 可以定义不同的虚拟机的日志存放在不同的文件中，便于管理。
						
						访问日志文件路径，格式及相关的缓冲的配置；
							buffer=size
							flush=time 
							
					33、open_log_file_cache max=N [inactive=time] [min_uses=N] [valid=time];
						open_log_file_cache off;
							缓存各日志文件相关的元数据信息；
							
							max：缓存的最大文件描述符数量；
							min_uses：在inactive指定的时长内访问大于等于此值方可被当作活动项；
							inactive：非活动时长；
							valid：验正缓存中各缓存项是否为活动项的时间间隔；
							
				ngx_http_gzip_module：
					The ngx_http_gzip_module module is a filter that compresses responses using the “gzip” method. This often helps to reduce the size of transmitted data by half or even more.
					
					1、gzip on | off;
						Enables or disables gzipping of responses.
						
					2、gzip_comp_level level;
						Sets a gzip compression level of a response. Acceptable values are in the range from 1 to 9.
						
					3、	gzip_disable regex ...;
						Disables gzipping of responses for requests with “User-Agent” header fields matching any of the specified regular expressions.
						
					4、	gzip_min_length length;
						启用压缩功能的响应报文大小阈值； 
						
					5、gzip_buffers number size;
						支持实现压缩功能时为其配置的缓冲区数量及每个缓存区的大小；
						
					6、gzip_proxied off | expired | no-cache | no-store | private | no_last_modified | no_etag | auth | any ...;
						nginx作为代理服务器接收到从被代理服务器发送的响应报文后，在何种条件下启用压缩功能的；
							off：对代理的请求不启用
							no-cache, no-store，private：表示从被代理服务器收到的响应报文首部的Cache-Control的值为此三者中任何一个，则启用压缩功能；
							
					7、gzip_types mime-type ...;
						压缩过滤器，仅对此处设定的MIME类型的内容启用压缩功能；
					
					8、gzip_vary on | off;
 						如果启用压缩，是否在响应报文首部插入“Vary: Accept-Encoding”

					9、gzip_proxied off | expired | no-cache | no-store | private | no_last_modified | no_etag | auth | any ...;
						nginx充当代理服务器时，对于后端服务器的响应报文，在何种条件下启
						用压缩功能
						off：不启用压缩
						expired，no-cache, no-store，private：对后端服务器的响应报文首部
						Cache-Control值任何一个，启用压缩功能

					示例：
						gzip  on;
						gzip_comp_level 6;
						gzip_min_length 64;
						gzip_proxied any;
						gzip_types text/xml text/css  application/javascript;						
																		
				ngx_http_ssl_module模块：
					
					1、	ssl on | off;1.15之后用listen替代ssl指令
						Enables the HTTPS protocol for the given virtual server.
						
					2、ssl_certificate file;
						当前虚拟主机使用PEM格式的证书文件；
						
					3、ssl_certificate_key file;
						当前虚拟主机上与其证书匹配的私钥文件；
						
					4、ssl_protocols [SSLv2] [SSLv3] [TLSv1] [TLSv1.1] [TLSv1.2];
						支持ssl协议版本，默认为后三个；
						
					5、ssl_session_cache off | none | [builtin[:size]] [shared:name:size];
						builtin[:size]：使用OpenSSL内建的缓存，此缓存为每worker进程私有；
						none：通知客户端支持ssl session cache，但实际不支持
						[shared:name:size]：在各worker之间使用一个共享的缓存；
						
					6、ssl_session_timeout time;
						客户端一侧的连接可以复用ssl session cache中缓存 的ssl参数的有效时长；

					7、nginx支持基于域名的多个虚拟主机加密。
						
					配置示例：
						server {
							listen 443 ssl;
							server_name www.zhanghw.com;
							root /vhosts/ssl/htdocs;
							ssl on;
							ssl_certificate /etc/nginx/ssl/nginx.crt;
							ssl_certificate_key /etc/nginx/ssl/nginx.key;
							ssl_session_cache shared:sslcache:20m;
						}	

					自签名证书制作：
						在/etc/pki/tls/certs 下
						make a.com.crt

							
回顾：
	arch：master/worker, cache loader, cache manager
	
	配置框架：
		main block
			worker_processes
			events {
				work_connections N
				...
			}
		http {
			...
			server {
				listen ...
				server_name ...
				location /URI/ {
					...
					if CONDITION {
						...
					}
					...
				}
			}
			server {
				...
			}
		}
		
		server, listen, server_name, location, root, alias

Nginx（3）
	
	配置参数：
		ngx_http_rewrite_module模块：
		
			The ngx_http_rewrite_module module is used to change request URI using PCRE regular expressions, return redirects, and conditionally select configurations.
			
			bbs.zhanghw.com/ --> www.zhanghw.com/bbs/,  http://www.zhanghw.com/ --> https://www.zhanghw.com/
			http://www.zhanghw.com/login.php;username=tom --> http://www.zhanghw.com/tom/
			
			
			将用户请求的URI基于regex所描述的模式进行检查，而后完成替换；
			
			1、rewrite regex replacement [flag]
				将用户请求的URI基于regex所描述的模式进行检查，匹配到时将其替换为replacement指定的新的URI；
				
				注意：如果在同一级配置块中存在多个rewrite规则，那么会自下而下逐个检查；被某条件规则替换完成后，会重新一轮的替换检查，因此，隐含有循环机制；[flag]所表示的标志位用于控制此循环机制；
				
				如果replacement是以http://或https://开头，则替换结果会直接以重向返回给客户端；
					301：永久重定向；
					
				[flag]： 
					last：重写完成后停止对当前URI在当前location中后续的其它重写操作，而后对新的URI启动新一轮重写检查；提前重启新一轮循环；响应码：200 
					break：重写完成后停止对当前URI在当前location中后续的其它重写操作，而后直接跳转至重写规则配置块之后的其它配置；结束循环；
					redirect：重写完成后以临时重定向方式直接返回重写后生成的新URI给客户端，由客户端重新发起请求；不能以http://或https://开头； 302
					permanent:重写完成后以永久重定向方式直接返回重写后生成的新URI给客户端，由客户端重新发起请求； 301

				location /bbs {
					rewrite ^/bbs/(.*)$  /forum/$1 last;  nginx里不能写\1引用前件，而是用$
				}	

				schema 变量实现http跳转到https:
					if ( $shceme = http){
						rewrite / https://www.a.com break;
					}
				
			2、return
				return code [text];
				return code URL;
				return URL;
				
				Stops processing and returns the specified code to a client. 
				301、302、303、307、308 跳转到URL
				
			3、	rewrite_log on | off;
				是否开启重写日志，发送至error_log
				
			4、	if (condition) { ... }
				引入一个新的配置上下文 ；条件满足时，执行配置块中的配置指令；server, location；
				
				condition：
					比较操作符：
						==
						!=
						~：模式匹配，区分字符大小写；
						~*：模式匹配，不区分字符大小写；
						!~：模式不匹配，区分字符大小写；
						!~*：模式不匹配，不区分字符大小写；
					文件及目录存在性判断：
						-e, !-e
						-f, !-f
						-d, !-d
						-x, !-x
						
			5、set $variable value;
				用户自定义变量 ；				
			
		ngx_http_referer_module模块：
			The ngx_http_referer_module module is used to block access to a site for requests with invalid values in the “Referer” header field. 
			
			1、valid_referers none | blocked | server_names | string ...;
				定义referer首部的合法可用值；不能匹配的将是非法值，可以防盗链。
					
					none：请求报文首部没有referer首部；
					blocked：请求报文的referer首部没有值；
					server_names：参数，其可以有值作为主机名或主机名模式；
						arbitrary_string：直接字符串，但可使用*作通配符；
						regular expression：被指定的正则表达式模式匹配到的字符串；要使用~打头，例如 ~.*\.zhanghw\.com；
						
				配置示例：
					valid_referers none block server_names *.zhanghw.com *.mageedu.com zhanghw.* mageedu.* ~\.zhanghw\.;			
					if($invalid_referer) {
						return 403;
					}
										
		
		ngx_http_proxy_module模块：
			转发请求至另一台主机
			同构代理：代理服务器和后端协议一样
			The ngx_http_proxy_module module allows passing requests to another server.
			
			1、proxy_pass URL;
				Context:	location, if in location, limit_except
				
				注意：proxy_pass后面的路径不带uri时，其会将location的uri传递给后端主机；
					
					server {
						...
						server_name HOSTNAME;
						location /uri/ {
							proxy_pass http://host[:port];
						}
						...
					}
					
					http://HOSTNAME/uri --> http://host/uri 

				上面示例：http://HOSTNAME/uri --> http://host/uri  
				如果上面示例中有 /，即：http://host[:port]/ 
				意味着：http://HOSTNAME/uri --> http://host/ 即置换
					
				如果：proxy_pass http://192.168.1.18   注意后面是否有/
					server {
						...
						server_name HOSTNAME;
						location /uri/ {
							proxy_pass http://192.168.1.18/
						}
						...
					}
					
					http://HOSTNAME/uri --> http://host
					
				proxy_pass后面的路径是一个uri时，其会将location的uri替换为proxy_pass的uri；
				
				不带/追加  带/替代


					server {
						...
						server_name HOSTNAME;
						location /uri/ {
							proxy_pass http://host/new_uri/;
						}
						...
					}
					
					http://HOSTNAME/uri/ --> http://host/new_uri/


					
				如果location定义其uri时使用了正则表达式的模式，则proxy_pass之后必须不能使用uri; 用户请求时传递的uri将直接附加代理到的服务的之后；
				
					server {
						...
						server_name HOSTNAME;
						location ~|~* /uri/ {
							proxy http://host;    用正则表达式的时候，host后面不能加/
						}
						...
					}
					
					http://HOSTNAME/uri/ --> http://host/uri/；
					
			2、proxy_set_header field value;
				设定发往后端主机的请求报文的请求首部的值；Context:	http, server, location
				
				proxy_set_header X-Real-IP  $remote_addr;  $remore_addr:远程客户端IP
				proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
				
				location / { 
                proxy_pass http://192.168.27.13/;
                proxy_set_header clientip $remote_addr;
                proxy_set_header host $host;  客户端请求的fqdn
        		}   

				
			3、proxy_cache_path
				定义可用于proxy功能的缓存；Context:	http			
				
				proxy_cache_path path [levels=levels] [use_temp_path=on|off] keys_zone=name:size [inactive=time] [max_size=size] [manager_files=number] [manager_sleep=time] [manager_threshold=time] [loader_files=number] [loader_sleep=time] [loader_threshold=time] [purger=on|off] [purger_files=number] [purger_sleep=time] [purger_threshold=time];
				
			4、proxy_cache zone | off;
				指明要调用的缓存，或关闭缓存机制；Context:	http, server, location
				
			5、	proxy_cache_key string;
				缓存中用于“键”的内容；
				
				默认值：proxy_cache_key $scheme$proxy_host$request_uri;
				
			6、proxy_cache_valid [code ...] time;
				定义对特定响应码的响应内容的缓存时长；
				
				定义在http{...}中；
				proxy_cache_path /var/cache/nginx/proxy_cache levels=1:1:1 keys_zone=pxycache:20m max_size=1g;
				
				定义在需要调用缓存功能的配置段，例如server{...}；
				proxy_cache pxycache;
				proxy_cache_key $request_uri;
				proxy_cache_valid 200 302 301 1h;
				proxy_cache_valid any 1m;

				示例：在http配置定义缓存信息
				proxy_cache_path /var/cache/nginx/proxy_cache 
					levels=1:1:1 keys_zone=proxycache:20m 
					inactive=120s max_size=1g; 
				说明：proxycache:20m 指内存中缓存的大小，主要用于存放key和metadata（如：使用次数） 
					max_size=1g 指磁盘存入文件内容的缓存空间最大值

				
			7、proxy_cache_use_stale
				
				proxy_cache_use_stale error | timeout | invalid_header | updating | http_500 | http_502 | http_503 | http_504 | http_403 | http_404 | off ...;
				在被代理的后端服务器出现那种情况下，可直接使用过期的缓存响应客户端
				Determines in which cases a stale cached response can be used when an error occurs during communication with the proxied server.
				
			8、proxy_cache_methods GET | HEAD | POST ...;
				If the client request method is listed in this directive then the response will be cached. “GET” and “HEAD” methods are always added to the list, though it is recommended to specify them explicitly. 
				对哪些客户端请求方法对应的响应进行缓存，GET和HEAD方法总是被缓存

			9、proxy_hide_header field;
				By default, nginx does not pass the header fields “Date”, “Server”, “X-Pad”, and “X-Accel-...” from the response of a proxied server to a client. The proxy_hide_header directive sets additional fields that will not be passed.
				默认nginx在响应报文中不传递后端服务器的首部字段Date, Server, X-Pad, X-Accel-等，用于隐藏后端服务器特定的响应首部
			10、proxy_connect_timeout time;
				Defines a timeout for establishing a connection with a proxied server. It should be noted that this timeout cannot usually exceed 75 seconds.
				
				定义与后端服务器建立连接的超时时长，如超时会出现502错误，默认为60s，一般不建议超出75s

			11、proxy_send_timeout time;
				将请求发送给后端服务器的超时时长；默认为60s
			12、proxy_read_timeout time;
				等待后端服务器发送响应报文的超时时长，默认为60s	
				
			
		ngx_http_headers_module模块
			The ngx_http_headers_module module allows adding the “Expires” and “Cache-Control” header fields, and arbitrary fields, to a response header.
			
			向由代理服务器响应给客户端的响应报文添加自定义首部，或修改指定首部的值；
			
			1、add_header name value [always];
				添加自定义首部；
				
				add_header X-Via  $server_addr;
				add_header X-Accel $server_name;
				
			2、expires [modified] time;
				expires epoch | max | off;
				
				用于定义Expire或Cache-Control首部的值；
									
						
						
		ngx_http_fastcgi_module模块：
			
			The ngx_http_fastcgi_module module allows passing requests to a FastCGI server.
			转发请求到FastCGI服务器，不支持php模块方式
			fastcgi参数文件：/etc/nginx/fastcgi_params
			1、fastcgi_pass address;
				address为fastcgi server的地址；	
				可用位置location, if in location；
				
			2、fastcgi_index name;
				fastcgi默认的主页资源;
				示例：fastcgi_index index.php; 

				主机默认主页：index index.php;
				在fastcgi模式中，如果设置了index,就不要再设置fastcgi_index ，不然会冲突
				
			3、fastcgi_param parameter value [if_not_empty];
				Sets a parameter that should be passed to the FastCGI server. The value can contain text, variables, and their combination.
				设置传递给 FastCGI服务器的参数值，可以是文本，变量或组合
				
			配置示例1：
				前提：配置好fpm server和mariadb-server服务；
					location ~* \.php$ {
						root           /usr/share/nginx/html;  这个可以省略
						fastcgi_pass   127.0.0.1:9000; 后端服务器地址
						fastcgi_index  index.php; 
						fastcgi_param  SCRIPT_FILENAME  /usr/share/nginx/html$fastcgi_script_name; 后端服务器存放php网页文件的地址
						include        fastcgi_params;
					}
					虚拟主机完整配置示例：
					server {
						listen 80 default_server;
						server_name www.b.com;
						index index.php;
						root /data/web/b;
						location / { 
					
						}    
						location ~* \.php$ {
								root /data/web/b;
								fastcgi_pass 127.0.0.1:9000;
						#       fastcgi_index index.php;
								fastcgi_param SCRIPT_FILENAME /data/web/b$fastcgi_script_name;
								include fastcgi_params;
						}   
						}

					
			配置示例2：通过/pm_status和/ping来获取fpm server状态信息；
				location ~* ^/(pm_status|ping)$ {
					include        fastcgi_params;
					fastcgi_pass 127.0.0.1:9000;   也可以使用socket接口实现交互
					fastcgi_param  SCRIPT_FILENAME  $fastcgi_script_name;
				}			
					
			4、fastcgi_cache_path path [levels=levels] [use_temp_path=on|off] keys_zone=name:size [inactive=time] [max_size=size] [manager_files=number] [manager_sleep=time] [manager_threshold=time] [loader_files=number] [loader_sleep=time] [loader_threshold=time] [purger=on|off] [purger_files=number] [purger_sleep=time] [purger_threshold=time];
			
				定义fastcgi的缓存；缓存位置为磁盘上的文件系统，由path所指定路径来定义；
				
					levels=levels：缓存目录的层级数量，以及每一级的目录数量；levels=ONE:TWO:THREE
						leves=1:2:2
					keys_zone=name:size
						k/v映射的内存空间的名称及大小
					inactive=time
						非活动时长
					max_size=size
						磁盘上用于缓存数据的缓存空间上限
					
			5、fastcgi_cache zone | off;
				调用指定的缓存空间来缓存数据；http, server, location
				
			6、fastcgi_cache_key string;
				定义用作缓存项的key的字符串；
				
			7、fastcgi_cache_methods GET | HEAD | POST ...;
				为哪些请求方法使用缓存；
				
			8、fastcgi_cache_min_uses number;
				缓存空间中的缓存项在inactive定义的非活动时间内至少要被访问到此处所指定的次数方可被认作活动项；
				
			9、fastcgi_cache_valid [code ...] time;
				不同的响应码各自的缓存时长；
				
				示例：
					http {
						...
						fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2:1 keys_zone=fcgi:20m inactive=120s;
						...
						server {
							...
							location ~* \.php$ {
								...
								fastcgi_cache fcgi;
								fastcgi_cache_key $request_uri;
								fastcgi_cache_valid 200 302 10m;
								fastcgi_cache_valid 301 1h;
								fastcgi_cache_valid any 1m;	
								...
							}
							...
						}
						...
					}
				
				10、fastcgi_keep_conn on | off;
					By default, a FastCGI server will close a connection right after sending the response. However, when this directive is set to the value on, nginx will instruct a FastCGI server to keep connections open.
						

	
	
	ngx_http_upstream_module模块   LVS
		The ngx_http_upstream_module module is used to define groups of servers that can be referenced by the proxy_pass, fastcgi_pass, uwsgi_pass, scgi_pass, and memcached_pass directives.
			
		1、upstream name { ... }
			定义后端服务器组，会引入一个新的上下文；Context: http
			
			upstream httpdsrvs {
				server 192.168.17.1;
				server 192.168.17.2;
				server 127.0.0.1:80 backup;  备用
			}
			location / {
				proxy_pass http://httpdsrvs;
			}
			
		2、server address [parameters];
			在upstream上下文中server成员，以及相关的参数；Context:	upstream
			
			address的表示格式：
				unix:/PATH/TO/SOME_SOCK_FILE
				IP[:PORT]
				HOSTNAME[:PORT]
				
			parameters：
				weight=number
					权重，默认为1；
				max_fails=number
					失败尝试最大次数；超出此处指定的次数时，server将被标记为不可用；
				fail_timeout=time
					设置将服务器标记为不可用状态的超时时长；
				max_conns
					当前的服务器的最大并发连接数；
				backup
					将服务器标记为“备用”，即所有服务器均不可用时此服务器才启用；
				down
					标记为“不可用”；
					
		3、least_conn;
			最少连接调度算法，当server拥有不同的权重时其为wlc;
			
		4、	ip_hash;
			源地址hash调度方法，同一IP往同一个服务器上调度。
			不支持backup

		5、hash key [consistent];
			基于指定的key的hash表来实现对请求的调度，此处的key可以直接文本、变量或二者的组合；
			
			作用：将请求分类，同一类请求将发往同一个upstream server；
			
			If the consistent parameter is specified the ketama consistent hashing method will be used instead.
				
			示例：
				hash $request_uri consistent; 一致性hash算法  hash环的偏移   
				hash $remote_addr;
				
		6、keepalive connections;
			为每个worker进程保留的空闲的长连接数量；
			
	nginx的其它的二次发行版：
		tengine
		OpenResty
		
	ngx_stream_core_module模块
		模拟反代基于tcp或udp的服务连接，即工作于传输层的反代或调度器；
		
		1、stream { ... }
			定义stream相关的服务；Context:main
			
			stream {
				upstream sshsrvs {
					server 192.168.22.2:22; 
					server 192.168.22.3:22; 
					least_conn;
				}

				server {
					listen 10.1.0.6:22022;
					proxy_pass http://sshsrvs;
				}
			}	
			
		2、listen
			listen address:port [ssl] [udp] [proxy_protocol] [backlog=number] [bind] [ipv6only=on|off] [reuseport] [so_keepalive=on|off|[keepidle]:[keepintvl]:[keepcnt]];
					
	
	思考：
		(1) 动态资源存储一组服务器、图片资源存在一组服务器、静态的文本类资源存储在一组服务器；如何分别调度？
		(2) 动态资源基于fastcgi或http协议（ap）?
			lnamp

memcached：

	memcached is a high-performance, distributed memory object caching system, generic in nature, but intended for use in speeding up dynamic web applications by alleviating database load.


	缓存服务器：
		缓存：cache，无持久存储功能；
		bypass缓存
		k/v cache，仅支持存储流式化数据；
		
	LiveJournal旗下的Danga Interactive研发，
	
		特性：
			k/v cache：仅可序列化数据；存储项：k/v；
			智能性一半依赖于客户端（调用memcached的API开发程序），一半依赖于服务端；
			分布式缓存：互不通信的分布式集群；
				分布式系统请求路由方法：取模法，一致性哈希算法；
			算法复杂度：O(1)
			清理过期缓存项：
				缓存耗尽：LRU 
				缓存项过期：惰性清理机制
			
	安装配置：
		由CentOS 7 base仓库直接提供：
			监听的端口：
				11211/tcp, 11211/udp 
				
		主程序：/usr/bin/memcached
		配置文件：/etc/sysconfig/memcached
		Unit File：memcached.service 
		
		协议格式：memcached协议
			文本格式
			二进制格式
			
		命令：
			统计类：stats, stats items, stats slabs, stats sizes
			存储类：set, add, replace, append, prepend
				命令格式：<command name> <key> <flags> <exptime> <bytes>  
				<cas unique>
			检索类：get, delete, incr/decr
			清空：flush_all
			
			示例：
				telnet> add KEY <flags> <expiretime> <bytes> \r
				telnet> VALUE
				
		memcached程序的常用选项：
			-m <num>：Use <num> MB memory max to use for object storage; the default is 64 megabytes.
			-c <num>：Use <num> max simultaneous connections; the default is 1024.
			-u <username>：以指定的用户身份来运行进程；
			-l <ip_addr>：监听的IP地址，默认为本机所有地址；
			-p <num>：监听的TCP端口， the default is port 11211.
			-U <num>：Listen on UDP port <num>, the default is port 11211, 0 is off.
			-M：内存耗尽时，不执行LRU清理缓存，而是拒绝存入新的缓存项，直到有多余的空间可用时为止；
			-f <factor>：增长因子；默认是1.25；
			-t <threads>：启动的用于响应用户请求的线程数；
			
		memcached默认没有认证机制，可借用于SASL进行认证；
			SASL：Simple Authentication Secure Layer
			
		API:
			php-pecl-memcache
			php-pecl-memcached
			python-memcached
			libmemcached
			libmemcached-devel
			
		命令行工具：
			memcached-tool  SERVER:PORT  COMMAND
			
      
Nginx(4)

	LB Cluster：
		传输层：lvs、nginx、haproxy
		应用层：nginx(http, https, smtp, pop, imap), haproxy(http), httpd(http/https), ats, perlbal, pound, ...
		
	nginx load balancer：
		tcp/udp

	nginx proxy：
		reverse proxy：
		
	应用程序发布：
		灰度模型：
			(1) 如果存在用户会话；
				从服务器上拆除会话；
			(2) 新版本应用程序存在bug；
				回滚；
				
	ngx_http_proxy_module
	
		(1) proxy_pass URL;
			location, if in location, limit_except
			
			注意：proxy_pass后面的路径不带uri时，其会将location的uri传递给后端主机；
			
				location /uri/ {
					proxy_pass http://HOST;
				}
				
			proxy_pass后面的路径是一个uri时，其会将location的uri替换为proxy_pass的uri；
				location /uri/ {
					proxy_pass http://HOST/new_uri/;
				}
				
			如果location定义其uri时使用正则表达式的模式，则proxy_pass之后必须不能使用uri；
				location ~|~* PATTERN {
					proxy_pass http://HOST;
				}
				
		(2) proxy_set_header field value;
			设定发往后端主机的请求报文的请求首部的值； 
		
			示例：
				proxy_set_header X-Real-IP $remote_addr;
				proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for
				
		(3) proxy_cache_path
		
			proxy_cache_path path [levels=levels] [use_temp_path=on|off] keys_zone=name:size [inactive=time] [max_size=size] [loader_files=number] [loader_sleep=time] [loader_threshold=time] [purger=on|off] [purger_files=number] [purger_sleep=time] [purger_threshold=time];
				
		(4) proxy_cache zone | off;
			调用的缓存的名称，或禁用缓存；
		
		(5) proxy_cache_key string;
			缓存条目的键；
		
		(6) proxy_cache_valid [code ...] time;
			对各类响应码的缓存时长；
			
		使用示例：
			定义在http{}中：
				proxy_cache_path /var/cache/nginx/proxy_cache levels=1:2:1 keys_zone=pcache:10m max_size=1g;
				
			定义在server{}及其内部的组件中：
				proxy_cache pcache;
				proxy_cache_key $request_uri;
				proxy_cache_valid 200 302 10m;
				proxy_cache_valid 301 1h;
				proxy_cache_valid any 1m;				
			
		(7) proxy_cache_use_stale error | timeout | invalid_header | updating | http_500 | http_502 | http_503 | http_504 | http_403 | http_404 | off ...;
		
		(8) 	proxy_connect_timeout
			proxy_read_timeout
			proxy_send_timeout
			
		(9)   proxy_buffer_size
			proxy_buffering
			proxy_buffers
			
	ngx_http_headers_module
		The ngx_http_headers_module module allows adding the “Expires” and “Cache-Control” header fields, and arbitrary fields, to a response header.
		
		(1) 	add_header name value [always];
			向响应报文中添加自定义首部；
			
			可用上下文：http, server, location, if in location
			
			add_header X-Via $server_addr;
			add_header X-Accel $server_name;

		(2) expires [modified] time;
			expires epoch | max | off;
			
			用于定义Expire或Cache-Control首部的值，或添加其它自定义首部；
			
回顾：
	LB Cluster：
		传输层：lvs, nginx(stream), haproxy(mode tcp)
		应用层：
			http/https：nginx(upstream), haproxy(mode http), httpd, ats, perlbal, pound, ...
			
		lvs：
			类型：nat/dr/tun/fullnat
			算法：
				静态：rr, wrr, sh, dh
				动态：lc, wlc, sed, nq, lblc, lblcr
				
		session保持：
			session sticky（SourceIP/Cookie）
			session replication cluster
			session server（redis/...）
			
	Nginx：
		web：web server, web reverse proxy
		mail：mail reverse proxy
		tcp/udp：stream module
		
		ngx_http_proxy_module
			proxy_path
			
			proxy_cache_path
			proxy_cache
			proxy_cache_key
			proxy_cache_valid
			proxy_cache_methods
			
Nginx(4)
			
	ngx_http_upstream_module	
		The ngx_http_upstream_module module is used to define groups of servers that can be referenced by the proxy_pass, fastcgi_pass, uwsgi_pass, scgi_pass, and memcached_pass directives.
		
		(1) upstream name { ... }
			定义后端服务器组；引入一个新的上下文；只能用于http{}上下文中；
			
			默认的调度方法是wrr；
			
		(2) server address [parameters];
			定义服务器地址和相关的参数；
				地址格式：
					IP[:PORT]
					HOSTNAME[:PORT]
					unix:/PATH/TO/SOME_SOCK_FILE
					
				参数：
					weight=number
						权重，默认为1；
					max_fails=number
						失败尝试的最大次数；
					fail_timeout=time
						设置服务器为不可用状态的超时时长；
					backup
						把服务器标记为“备用”状态； 
					down
						手动标记其为不可用；
					
		(3) least_conn;
			最少连接调度算法； 当server拥有不同的权重时为wlc；当所有后端主机的连接数相同时，则使用wrr进行调度；
			
		(4) least_time header | last_byte;
			最短平均响应时长和最少连接；
			header：response_header; 
			last_byte: full_response; 
			
			仅Nginx Plus有效；
			
		(5) ip_hash;
			源地址hash算法；能够将来自同一个源IP地址的请求始终发往同一个upstream server；
			
		(6) hash key [consistent];
			基于指定的key的hash表实现请求调度，此处的key可以文本、变量或二者的组合；
			
			consistent：参数，指定使用一致性hash算法；
			
			示例：
				hash $request_uri consistent
				hash $remote_addr
				hash $cookie_name
				
		(7) keepalive connections;
			可使用长连接的连接数量；
			
		(8) health_check [parameters];
			定义对后端主机的健康状态检测机制；只能用于location上下文；
			
			可用参数：
				interval=time：检测频率，默认为每隔5秒钟；
				fails=number：判断服务器状态转为失败需要检测的次数；
				passes=number：判断服务器状态转为成功需要检测的次数；
				uri=uri：判断其健康与否时使用的uri；
				match=name：基于指定的match来衡量检测结果的成败；
				port=number：使用独立的端口进行检测；
				
			仅Nginx Plus有效；
				
		(9) match name { ... }
			Defines the named test set used to verify responses to health  requests.
			定义衡量某检测结果是否为成功的衡量机制；
			
			专用指令：
				status：期望的响应码；
					status CODE
					status ! CODE
					...
				header：基于响应报文的首部进行判断
					header HEADER=VALUE
					header HEADER ~ VALUE 
					...
				body：基于响应报文的内容进行判断
					body ~ "PATTERN"
					body !~ "PATTERN"
					
			仅Nginx Plus有效；
			
	博客作业：以上所有内容；
	课外实践：实践tengine和Openresty；
		
	ngx_stream_core_module
	
		The ngx_stream_core_module module is available since version 1.9.0. This module is not built by default, it should be enabled with the --with-stream configuration parameter.
		
		(1) listen address:port [ssl] [udp] [backlog=number] [bind] [ipv6only=on|off] [reuseport] [so_keepalive=on|off|[keepidle]:[keepintvl]:[keepcnt]];
			监听的端口；
				默认为tcp协议；
				udp: 监听udp协议的端口；
				
	ngx_stream_proxy_module
		
		The ngx_stream_proxy_module module (1.9.0) allows proxying data streams over TCP, UDP (1.9.13), and UNIX-domain sockets.
		
		(1) proxy_pass address;
			Sets the address of a proxied server. The address can be specified as a domain name or IP address, and a port or as a UNIX-domain socket path.
			
		(2) proxy_timeout timeout;
			Sets the timeout between two successive read or write operations on client or proxied server connections. If no data is transmitted within this time, the connection is closed.
			
			默认为10m; 
			
		(3) proxy_connect_timeout time;
			Defines a timeout for establishing a connection with a proxied server.
			
			设置nginx与被代理的服务器尝试建立连接的超时时长；默认为60s；
						
	
		示例：
			stream {
				upstream sshsrvs {
					server 192.168.10.130:22;
					server 192.168.10.131:22;
					hash $remote_addr consistent;
				}

				server {
					listen 172.16.100.6:22202;
					proxy_pass sshsrvs; 
					proxy_timeout 60s;
					proxy_connect_timeout 10s;
				}
			}		
					
	编译安装：
		前提：开发环境，包括nginx编译要启用的功能依赖到的开发库；
			# yum groupinstall "Development Tools" "Server Platform Development"
			# yum -y pcre-devel openssl-devel
			
		编译过程：
			# ./configure --prefix=/usr/local/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --user=nginx --group=nginx --with-http_ssl_module  --with-http_stub_status_module --with-http_flv_module --with-http_mp4_module --with-threads --with-file-aio
			# make && make install
			
	课程实践：
		nginx--> AMPs（wordpress）
		nginx--> FPMs（wordpress）
		
		nginx--> images servers ( imgs.zhanghw.com）
					location ~* \.(jpg|png|gif|jpeg)$ {
						...
					}
			       dynamic content servers (shop.zhanghw.com)
					location ~* \.php$ {
						...
					}
					
					location / {
						...
					}
					
		自定义错误404和5xx错误页，文本静态内容传输压缩；
		
		
		
					
