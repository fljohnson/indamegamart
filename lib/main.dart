import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindful_in_market/itemdetailpage.dart';
import 'package:mindful_in_market/shoplist_data.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static bool get isIOS => true;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    initData();
    if(isIOS)
    {
      return CupertinoApp(
        home: MyHomePage(title: 'Flutteur Demo Home Page'),
        title: 'Flutteur Demo',

      );
    }
    else
    {
      return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter Demo Home Page'),
      );
    }

  }
}

class MyHomePage extends StatefulWidget {
  final List<Shoplist> _currentList = []; //need an immutable holder

  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  BuildContext _activeContext;

  bool editMode = false;

  List<Shoplist> lines = [];

  String get listTitle => (widget._currentList.isEmpty) ?
    "Please create a list":
   widget._currentList[0].name;


  @override
  void initState() {
    if(!initialLoadDone)
      {
        addWaker(() {
          Shoplist.getIthList(0).then((nuList){
            setState(() {
              widget._currentList.clear();
              widget._currentList.add(nuList);
            });

          });

          /*
          Shoplist.getLists().then((setOf){
            lines = setOf;


            Shoplist newList = lines[0];
            Future<int>(() async{
              await newList.load();
              return newList.length;
            }).then((aha){
              setState((){
                widget._currentList = newList;
              });
            });
          });
          */


          ///

        });
      }
    super.initState();
  }

  void getListMaterial()
  {
    print("Allo");
  }

  void getListCupertino()
  {
    Future<Shoplist> resultHolder= showCupertinoModalPopup<Shoplist>(
      context:_activeContext,
      builder: drawListChoices,
    );
    resultHolder.then((result)
    {
      if(result == null)
      {
        print("No action");
      }
      else
      {
        Shoplist newList = result;
        Future<int>(() async{
          await newList.load();
          return newList.length;
        }).then((aha){
          setState((){
            widget._currentList.clear();
            widget._currentList.add(result);
          });
        });

      }

    });
  }
  Widget chooseListBtn() {
    String btnTitle = "Change...";
    if(MyApp.isIOS)
    {
      return CupertinoButton(
        child:Text(btnTitle),
        onPressed:((){
          Shoplist.getLists().then((bunch){
            this.lines = bunch;
            getListCupertino();
          });
        })
      );
    }
    else
    {
      return MaterialButton(
        child:Text(btnTitle),
        onPressed:getListMaterial
      );
    }
  }
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  Widget listBlock()
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:<Widget>[
        Text(listTitle),
        chooseListBtn()
      ],
    );
  }

  Widget plannedTotalRow()
  {
    String total= (widget._currentList == null) ? "0.00" : widget._currentList[0].strPlannedTotal();

    return Row(
        mainAxisAlignment:MainAxisAlignment.center,
      children:[
        Text("Planned total (pre-tax):"),
        Text("\$$total")
      ]
    );
  }

  Widget currentTotalRow()
  {
    String total= (widget._currentList.isEmpty) ? "0.00" : widget._currentList[0].strCurrentTotal();
    TextStyle styleHowAmI = numBlack;
    if(widget._currentList.isNotEmpty && widget._currentList[0].overage )
    {
      styleHowAmI = numRed;
    }
    return Row(
      mainAxisAlignment:MainAxisAlignment.center,
        children:[
          Text("Current running total (pre-tax):"),
          Text("\$$total",style: styleHowAmI,)
        ]
    );
  }

  Widget runningTotalBlock()
  {
    return Column(
        children:[
          currentTotalRow(),
          plannedTotalRow(),
        ]
    );
    /*
    return Expanded(
        child:
    );*/
  }
  Widget itemsList()
  {
    if(widget._currentList.isEmpty)
      {
        return Text("");
      }

    List<Widget> headerContent = [];

    if(this.editMode)
    {
      headerContent.add(
          Container(width:30.0) //play the percentages
      );
    }

    headerContent.addAll(<Widget>[
      Container(
          margin: EdgeInsets.only(right:4.0),
          child:Text("In Cart?", textAlign: TextAlign.center)
      ),
      Container(
        child:Text("How\nMany", textAlign: TextAlign.center),
        margin:EdgeInsets.only(right:8.0,left:4.0),
      )
      ,
      Expanded(
        flex:2,
        child: Text("Item", textAlign: TextAlign.center),
      )
      ,
      Container(
        child:Text("Total\nPrice", textAlign: TextAlign.center),
        margin:EdgeInsets.only(left:4.0),
      )
      ,

      Container(width:50.0) //play the percentages
    ]
    );

    Row header = Row(
      children:headerContent
    );

    int numrows = widget._currentList[0].length;
    if(this.editMode)
    {
      numrows += 1;
    }
    Widget list = ListView.builder(
      padding: EdgeInsets.all(0.0),
      itemCount:numrows,
      itemBuilder: ((context,index){
        List<Widget> rowContent = [];
        if(index == widget._currentList[0].length && this.editMode)
        {
          rowContent.add(
              CupertinoButton(
                  child: Icon(CupertinoIcons.add_circled),
                  onPressed:((){
                    DetailPage.list = widget._currentList[0];
                    DetailPage.item = null;
                    Navigator.push(context,
                      CupertinoPageRoute<bool>(
                        maintainState: false,
                        fullscreenDialog: false,
                        builder: detailPageBuilder
                      )
                    ).then((saved)
                    {
                      if(saved == true)
                      {
                        print("saved");
                        widget._currentList[0].load().then((bupkis){
                          setState((){
                            //widget._currentList.primeReload();
                          });
                        });
                      }
                      else
                        {
                          print("nixed");
                        }

                    });
                  })
              )

          );
          rowContent.add(
              Expanded(
                flex:2,
                child: Text("add new item",style:TextStyle(inherit:true,color:Colors.blueGrey)),
              )

          );
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: rowContent
          );
        }
        RelListItem itemLine = widget._currentList[0].getIthItem(index);

        /*
        return CupertinoButton(
          //child:Text(itemLine.name), //qty, gotten, and totalprice go here too
          child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CupertinoSwitch(
                value:itemLine.gotIt,
              ),
              Text(itemLine.strQty),
              Text(itemLine.name),
              Text(itemLine.strPrice),
            ]
          ),
          onPressed: ((){
     //       Navigator.pop(context,listLine);
          }),
        );
        */

        if(this.editMode)
        {
          rowContent.add(
            CupertinoButton(
              child: Icon(CupertinoIcons.minus_circled),
              onPressed:((){
                doConfirmedDelete(context,itemLine).then((hitOK){
                  if(hitOK)
                  {

                    itemLine.visible = false;
                    updateItemStatus(itemLine).then((bupkis) async {
                      await widget._currentList[0].load();
                      setState((){
                        //widget._currentList.primeReload();
                      });
                    });
                  }
                });

              })
            )

          );
        }

        rowContent.addAll(<Widget>[
          Container(
            margin: EdgeInsets.only(right:4.0),
            child:CupertinoSwitch(
              value:itemLine.gotIt,
              onChanged: ((value) {
                itemLine.gotIt = value;
                updateItemStatus(itemLine).then((bupkis) async {
                  await widget._currentList[0].load();
                  setState(() {

                  });
                });
                /*
                widget._currentList.load().then((nothing){
                  setState(() {
                   // widget._currentList.primeReload();
                  });
                });
                */
              }),
            )
          ),
          Container(
            child:Text(itemLine.strQty),
            margin:EdgeInsets.only(right:12.0,left:4.0),
          )
          ,
          Expanded(
            flex:2,
            child: Text(itemLine.name),
          )
          ,
          Container(
            child:Text(itemLine.strPrice),
            margin:EdgeInsets.only(left:4.0),
          )
          ,
          CupertinoButton(
              child:Icon(CupertinoIcons.forward),
              onPressed:((){
                DetailPage.list = widget._currentList[0];
                DetailPage.item = itemLine;
                Navigator.push(context,
                    CupertinoPageRoute<bool>(
                        maintainState: false,
                        fullscreenDialog: false,
                        builder: detailPageBuilder
                    )
                ).then((saved)
                {
                  if(saved == true)
                  {
                    print("saved");

                    widget._currentList[0].load().then((bupkis){
                      setState((){
                     //   widget._currentList.primeReload();
                      });
                    });

                    /*
                    setState((){
                         widget._currentList.primeReload();
                    });
                    */
                  }
                  else
                  {
                    print("nixed");
                  }

                });
              })
          )
        ]
        );

        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowContent
        );
      }),
    );

    return Column(

        children:[
          header,
          Expanded(child:list)
        ]
      );
  }
  Widget itemsBlock()
  {

    return Expanded(
      child:itemsList()
    );

/*
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        itemsList()
      ],
    );
*/
  }
  Widget pageContent()
  {
    return Column(
      // Column is also layout widget. It takes a list of children and
      // arranges them vertically. By default, it sizes itself to fit its
      // children horizontally, and tries to be as tall as its parent.
      //
      // Invoke "debug painting" (press "p" in the console, choose the
      // "Toggle Debug Paint" action from the Flutter Inspector in Android
      // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
      // to see the wireframe for each widget.
      //
      // Column has various properties to control how it sizes itself and
      // how it positions its children. Here we use mainAxisAlignment to
      // center the children vertically; the main axis here is the vertical
      // axis because Columns are vertical (the cross axis would be
      // horizontal).
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        listBlock(),
        runningTotalBlock(),
        itemsBlock(),
        Text(
          'You have pushed the button this many times:',
        ),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.display1,
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    _activeContext = context;
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    if(MyApp.isIOS)
      {
        if(!initialLoadDone)
          {
            return CupertinoPageScaffold(
              backgroundColor: Colors.white,
              child:Center(
                  child:CupertinoActivityIndicator(radius:24)
              )
            );
          }
        return CupertinoPageScaffold(
          navigationBar:CupertinoNavigationBar(
            middle:Text(widget.title),
            backgroundColor:Colors.white,
            trailing:(widget._currentList.isNotEmpty) ? CupertinoButton(
              child:Text(this.editMode ? "Done":"Edit"),
              onPressed: ((){
                setState((){
                  this.editMode = !editMode;
                });

              }),
              padding: EdgeInsets.all(0.0)
            ) :
                null
          ),
          child: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: pageContent(),
          )
        );
      }
      else
        {
          return Scaffold(
            appBar: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text(widget.title),
            ),
            body: Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: pageContent(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
        }

  }

  Widget drawListChoices(BuildContext context) {
    /*
    List<TableRow> rows = [];
    Shoplist.getLists().forEach((listLine){
      rows.add(TableRow(
        children:[
          CupertinoButton(
            child:Text(listLine.name),
            onPressed: ((){
              Navigator.pop(context,listLine);
            }),
          )

        ]
      ));
    });
    */
/*
    var laTable = Table(
      children: rows,
      border:TableBorder(horizontalInside: BorderSide(width: 1.0))
    );
*/

    List<Widget> rows = [];
      this.lines.forEach((listLine){
      rows.add(
            CupertinoButton(
              child:Text(listLine.name),
              onPressed: ((){
                Navigator.pop(context,listLine);
              }),
            )

      );
    });
    var laTable = ListView.separated(
      padding: EdgeInsets.all(0.0),
      itemCount:lines.length,
      itemBuilder: ((context,index) {

        Shoplist listLine = lines[index];
        return CupertinoButton(
          child:Text(listLine.name),
          onPressed: ((){
            Navigator.pop(context,listLine);
          }),
        );
      }),
      separatorBuilder: ((context,index){
        return Container(
          width:window.physicalSize.width,
          height:1.0,
          color:Colors.black38
        );
      }),
    );
    var realheight = window.physicalSize.height / window.devicePixelRatio;

    return Container(
      color:Colors.white,
        constraints: BoxConstraints.expand(
          height: realheight*.540,
          width: window.physicalSize.width
        ),
        alignment: Alignment.center,
        child: Column(
          children:[
            CupertinoButton(
              child:Text("New List..."),
              onPressed: ((){

                TextEditingController goods = TextEditingController();
                Future<bool> holder = showCupertinoDialog<bool>(context:context,builder:(
                        (context){
                    return askForText(context, "Enter name of new list",goods);
                })
                );
                holder.then((hitOK)
                {
                    if(!hitOK)
                    {
                      Navigator.pop(context,null);
                    }
                    else {

                    String newvalue = goods.text;
                    Shoplist.newList(newvalue).then((rv){
                      Navigator.pop(context, rv);
                    });

                  }
                });
              }),
            ),

            /*
            CupertinoTextField(
              placeholder:"New List",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize:18.0, color:Colors.black),
              onSubmitted:((newvalue){
                var rv=Shoplist.newList(newvalue);
                if(rv!=null)
                  {
                    Navigator.pop(context,rv);
                  }
              })
            ),
            */
            Container(
                width:window.physicalSize.width,
                height:1.0,
                color:Colors.black38
            ),
            Expanded(
              child: laTable
            ),
            Container(
                width:window.physicalSize.width,
                height:1.0,
                color:Colors.black38
            ),
            CupertinoButton(
              child:Text("Cancel"),
              onPressed: ((){
                Navigator.pop(context,null);
              })
            )
          ]
        )
    );
  }

  void hitFunction()
  {
    print("HIT");
  }

  Widget detailPageBuilder(BuildContext context) {
    //seriously? HERE?!
    return DetailPage();

  }
}





bool editedItem(int listID,RelListItem itemLine) {
//    holder.then((saved)
    return true;
}

Future<bool> doConfirmedDelete(BuildContext context, RelListItem itemLine) {
  return showCupertinoDialog<bool>(context:context,builder:(
          (context){
        return askForConfirmation(context, "Remove item \"${itemLine.name}\"?");
      })
  );
}

Widget askForText(BuildContext context,String s,TextEditingController txtr, {bool numeric:false}) {
  TextInputType kbd = numeric ? TextInputType.numberWithOptions(decimal:true) :TextInputType.text;
  return CupertinoAlertDialog(title:Text(s),
      content:CupertinoTextField(
        keyboardType: kbd,
        controller:txtr
      ),
    actions:[
      CupertinoDialogAction(child:Text("Cancel"),isDefaultAction:true,onPressed:((){
        Navigator.pop(context,false);
      })),
      CupertinoDialogAction(child:Text("OK"),onPressed:((){
        Navigator.pop(context,true);
      })),
    ]

  );
}

Widget askForConfirmation(BuildContext context,String message) {
  return CupertinoAlertDialog(title:Text(message),
      actions:[
        CupertinoDialogAction(child:Text("Cancel"),isDefaultAction:true,onPressed:((){
          Navigator.pop(context,false);
        })),
        CupertinoDialogAction(child:Text("OK"),onPressed:((){
          Navigator.pop(context,true);
        })),
      ]

  );
}

TextStyle numBlack = TextStyle(inherit: true);
TextStyle numRed = TextStyle(inherit: true,color:Colors.redAccent);