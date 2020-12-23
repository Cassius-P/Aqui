import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:localstorage/localstorage.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqui',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WebPage(),
    );
  }
}

class WebPage extends StatefulWidget {
  @override
  _WebPageState createState() => _WebPageState();
}


class _WebPageState extends State<WebPage> {
  InAppWebViewController webView;
  String indexUrl = 'https://aqui.e-node.net/';

  bool showErrorPage = false;
  bool loading = true;
  String url ="";

  LocalStorage storage = new LocalStorage('/uris');
  JsonCodec json = JsonCodec();

  @override
  void initState() {
    super.initState();
  }

/*
  @override
  Widget build(BuildContext context) {

    return Scaffold(

        body: Container(
            child: Column(children: <Widget>[
              Expanded(

                child: Container(

                  child: InAppWebView(
                    //initialUrl: "https://aqui.e-node.net",
                    initialData: InAppWebViewInitialData(data : kNavigationExamplePage),
                    initialHeaders: {},
                    onWebViewCreated: (InAppWebViewController controller) {
                      webView = controller;


                    },

                    onLoadStart: (InAppWebViewController controller, String url) async {

                      var connectivityResult = await (Connectivity().checkConnectivity());
                      if (connectivityResult == ConnectivityResult.none) {
                        await controller.loadData(data: json.decode(await getHTML(storage, url)));
                      }
                    },
                    onLoadStop: (InAppWebViewController controller, String url) async {
                      var connectivityResult = await (Connectivity().checkConnectivity());
                      if (connectivityResult != ConnectivityResult.none) {
                        await controller.getHtml().then((value) => {
                          insertStorage(url, storage,value)
                        });
                      }

                    },
                    onLoadError: (InAppWebViewController controller, String url, int code, String message) async {
                      var tRexHtml = await controller.getTRexRunnerHtml();
                      var tRexCss = await controller.getTRexRunnerCss();
                      await getHTML(storage, url);





                    },
                    onLoadHttpError: (InAppWebViewController controller, String url, int statusCode, String description) async {
                      print("HTTP error $url: $statusCode, $description");
                    },
                    showErrorPage ? Center(
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        height: double.infinity,
                        width: double.infinity,
                        child: Text('Page failed to open (WIDGET)'),
                      ),
                    ) : SizedBox(height: 0, width: 0),
                  ),
                ),
              ),
            ]))
    );

  }*/


  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[

          InAppWebView(
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                useOnLoadResource: true,
                useOnDownloadStart: true,
                javaScriptEnabled: true,
                cacheEnabled: true,
              )
            ),
            onWebViewCreated: (InAppWebViewController controller) async{
              webView = controller;

              await this.isIndexInitialisable() ? webView.loadUrl(url: indexUrl) : webView.loadData(data: json.decode(await getHTML(storage, indexUrl)));
            },

            shouldOverrideUrlLoading: (controller, request) async {
              return this.doLoadUrl(controller, request);
            },

            onLoadStart: (InAppWebViewController controller, String url) async {
              setLoad();
              var connectivityResult = await (Connectivity().checkConnectivity());
              if (connectivityResult == ConnectivityResult.none && await getHTML(storage, url) != null) {
                await controller.loadData(data: json.decode(await getHTML(storage, url)), baseUrl: url);
              }
            },

            onLoadStop: (InAppWebViewController controller, String url) async {
              var connectivityResult = await (Connectivity().checkConnectivity());
              if (connectivityResult != ConnectivityResult.none) {
                if(url != "about:blank"){
                  await controller.getHtml().then((value) => {
                    insertStorage(url, storage,value)
                  });
                }
              }
              String htmlExist = await getHTML(storage, url);
              bool condition = loading && htmlExist != null;
              print("Stop the loader if html exist: $condition, \n$htmlExist");
              if(loading && htmlExist != null){
                Timer(Duration(seconds: 2), () => {
                  hideError()
                });
              }
            },

            onLoadError: (
                InAppWebViewController controller,
                String url,
                int i,
                String s
                ) async {
              showError();
              Timer(Duration(seconds: 2), () => {
                stopLoad()
              });
              this.url = url;
            },

            onLoadHttpError: (InAppWebViewController controller, String url,
                int i, String s) async {
              showError();
              Timer(Duration(seconds: 2), () => {
                stopLoad()
              });
              this.url = url;
            },
          ),

          showErrorPage ? Center(
            child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              height: double.infinity,
              width: double.infinity,
              child: loading ? Positioned(
                top:(MediaQuery.of(context).size.height/2)-50,
                left:(MediaQuery.of(context).size.width/2)-50,
                child:Card(
                  elevation: 6,
                  color: Colors.black45,
                  child: Container(
                    width: 100,
                    height:100,
                    padding: EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              ) : Positioned(
                  top:(MediaQuery.of(context).size.height/2)-75,
                  left:(MediaQuery.of(context).size.width/2)-100,
                  child:Card(
                    elevation: 6,
                    color: Colors.black45,
                    child: Container(
                      width: 200,
                      height:150,
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            "Une erreur s'est produite, veuillez vous connecter à internet avant de rééssayer",
                            style: TextStyle(color: Colors.white),
                          ),
                          ButtonBar(
                            alignment: MainAxisAlignment.center,
                            children: <Widget>[
                              RaisedButton(
                                child: Icon(Icons.refresh),
                                onPressed: () async {
                                  if (webView != null) {
                                    var connectivityResult = await (Connectivity().checkConnectivity());
                                    if (connectivityResult != ConnectivityResult.none) {
                                      webView.loadUrl(url: this.url);
                                      setLoad();
                                    }
                                  }
                                },
                              )
                            ])
                        ],
                      ),
                    ),
                  )
              ),
            ),
          ) : SizedBox(height: 0, width: 0),
        ],
      ),
    );
  }


  void showError(){
    setState(() {
      this.showErrorPage = true;
    });
  }

  void hideError(){
    setState(() {
      this.showErrorPage = false;
    });
  }

  void setLoad(){
    setState(() {
      this.loading = true;
    });
  }

  void stopLoad(){
    setState(() {
      this.loading = false;
    });
  }


  Future<bool> isIndexInitialisable() async{
    bool initWithUrl = true;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none && await getHTML(this.storage, this.indexUrl) != null) {
      initWithUrl = false;
    }
    return initWithUrl;
  }

  Future<void> readHTML(InAppWebViewController _controller, LocalStorage storage, String url) async {
    await _controller.getHtml().then(
            (value) =>
        {
          if(url != "about:blank" && value != null ){
            this.insertStorage(url, storage, value)
          }
        }
    );
  }


  void insertStorage(String url, LocalStorage storage, String html2) async{
    if(html2 != null && url != "about:blank"){
      JsonCodec json = JsonCodec();
      await storage.setItem(url,json.encode(html2));
      print("Insert $url : " + await storage.getItem(url) );
    }
  }

  Future<String> getHTML(LocalStorage storage, String url) async {
    String html = await storage.getItem(url);
    print("HTML of $url : '$html'");
    return html;
  }

  Future<ShouldOverrideUrlLoadingAction> doLoadUrl(InAppWebViewController controller, ShouldOverrideUrlLoadingRequest request) async{
    String url = request.url;
    if(request.url.startsWith(indexUrl)){
      print(" $url allowed");
      return ShouldOverrideUrlLoadingAction.ALLOW;
    }else{
      print("$url declined");
      await launch(url);
      return ShouldOverrideUrlLoadingAction.CANCEL;
    }
  }
}



