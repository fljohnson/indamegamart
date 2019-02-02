import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:mindful_in_market/shoplist_data.dart';

class DetailPage extends StatefulWidget {
  static Shoplist list;
  static RelListItem item;

  @override
  _DetailPageState createState() {
    return _DetailPageState();
  }

}

class _DetailPageState extends State<DetailPage>
{

  TextEditingController ctlrQty;
  TextEditingController ctlrUnitPrice;
  TextEditingController ctlrItemName;
  TextEditingController ctlrRowPrice;
  TextEditingController ctlrNotes;
  String possItem;
  List<String> maybeItemNames;
  bool itemNameClicked;

  Map<String,String> errors = Map<String,String>();

  Map<String,dynamic> _ship = {};

  Widget nameSelector() {
    if(maybeItemNames.length == 0)
    {
      /*
      return SizedBox.shrink(
          child:ListView(
            shrinkWrap: true,
            children: <Widget>[],
          )

      );
      */
      return Container(
        height: 0,
        width: 0,
      );
    }

    List<Widget> labels = [];
    maybeItemNames.forEach((linea){
      labels.add(
        FlatButton(
          child:Text(linea),
          onPressed:((){
   //         itemNameClicked = true;
            setState((){
              maybeItemNames.clear();
              ctlrItemName.text = linea;
            });

          })
        )
      );
    });
    return Container(
      color: CupertinoColors.white,
        child:ListView(
          shrinkWrap: true,
          children: labels,
        )
    );
  }

  Widget nameSelectorOverlay()
  {
    return Overlay(
        initialEntries:[OverlayEntry(builder:
            makeita,
        ),
        OverlayEntry(builder:makedos)]
    );
  }

  Widget makedos(BuildContext context){
    /*
    return SizedBox(
      //backgroundColor: Colors.yellow,
      height:200.0,
      width:500.0,

      child:nameSelector()
    );
    */
    return Positioned(
      top:60.0,
      left: 0,
      height: 300.0,
      width:400.0,
      child:nameSelector(),

    );
  }
  Widget makeita(BuildContext context){
    return pageContent();
  }

  @override
  void initState() {
    if(DetailPage.item == null) {
      ctlrQty = TextEditingController();
      ctlrNotes = TextEditingController();
      ctlrUnitPrice = TextEditingController();
      ctlrItemName = TextEditingController();
      ctlrRowPrice = TextEditingController();
    }
    else
    {
      ctlrQty = TextEditingController(text:DetailPage.item.strQty);
      ctlrNotes = TextEditingController(text:DetailPage.item.notes);
      ctlrUnitPrice = TextEditingController(text:DetailPage.item.strUnitprice);
      ctlrItemName = TextEditingController(text:DetailPage.item.name);
      ctlrRowPrice = TextEditingController(text:DetailPage.item.strPrice);
    }
    possItem = "";
    maybeItemNames = [];
    itemNameClicked = false;
    super.initState();
  }

  @override
  void dispose() {
    ctlrQty.dispose();
    ctlrNotes.dispose();
    ctlrUnitPrice.dispose();
    ctlrItemName.dispose();
    ctlrRowPrice.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    String title = (DetailPage.item == null) ? "Adding new item" : "Editing ${DetailPage.item.name}";
    return CupertinoPageScaffold(
        navigationBar:CupertinoNavigationBar(
            middle:Text(title),
            backgroundColor:Colors.white,
            trailing:CupertinoButton(
                child:Text("Done"),
                onPressed: ((){
                  if(!updateItem())
                    {

                      print(errors.keys.length);
                    }
                   else
                     {
                       Shopitem.newItem(DetailPage.list.id, this._ship['name'], this._ship['totalPrice'],this._ship['qty'], this._ship['notes']).then((bupkis){
                         if(DetailPage.item != null && DetailPage.item.name.trim() != _ship['name'].trim())
                         {
                           DetailPage.item.visible = false;
                           updateItemStatus(DetailPage.item).then((bupkis){
                             setState((){
                               Navigator.pop(context,true);
                             });
                           });
                         }
                         else
                         {
                           setState((){
                             Navigator.pop(context,true);
                           });
                         }
                       });

                     }

                }),
                padding: EdgeInsets.all(0.0)
            )
        ),
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child:
          nameSelectorOverlay(),
        )
    );
  }

  Widget pageContent()
  {
    return Column(
      children: <Widget>[
        CupertinoTextField(
          placeholder: "Qty (usually number of packages or pounds)",
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          controller: ctlrQty,
        ),

        CupertinoTextField(
          placeholder: "Item name",
          keyboardType: TextInputType.text,
          controller: ctlrItemName,
          onChanged: ((tempValue){
            if(itemNameClicked)
            {
              itemNameClicked = false;
              return;
            }
            if(tempValue.trim() != possItem)
            {
              //List<String> suspects = Shopitem.getItemSuggestions(tempValue.trim());
              Shopitem.getItemSuggestions(tempValue.trim()).then((suspects){
                if(suspects.length > 0)
                {
                  //update some stuff
                  possItem = tempValue.trim();
                  setState(() {
                    maybeItemNames = suspects;
                  });
                }
                else
                {
                  setState(() {
                    maybeItemNames.clear();
                  });
                }
              });
            }
          }),
        ),
        //nameSelectorOverlay(),
        CupertinoTextField(
          placeholder: "Unit Price (if applicable)",
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          controller: ctlrUnitPrice,
        ),
        CupertinoTextField(
          placeholder: "Total Price",
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          controller: ctlrRowPrice,
        ),
        CupertinoTextField(
          placeholder: "Notes",
          controller: ctlrNotes,
        ),

      ],
    );
  }

  bool updateItem() {
    this.errors.clear();
    num qty = numParse(ctlrQty.text,2);
    if(qty == 0)
    {
      qty = 1;
    }


    String name = ctlrItemName.text;
    if(name.isEmpty)
    {
      this.errors["itemname"]="Please give a name for this item";
      //return false;
    }
    num unitPrice = numParse(ctlrUnitPrice.text,2);
    num totalPrice = numParse(ctlrRowPrice.text,2);
    if(unitPrice == 0 && totalPrice == 0)
    {
      this.errors["unitprice"]="Please enter either a price per package or the total price for this item";
    }
    if(DetailPage.item != null && DetailPage.item.strPrice.trim() == ctlrRowPrice.text.trim())
    {
      totalPrice = qty * unitPrice;
    }
    if(totalPrice == 0)
    {
      totalPrice = qty * unitPrice;
    }
    String notes = ctlrNotes.text;
    if(notes.isEmpty)
    {
      notes = null;
    }
    if(this.errors.keys.length > 0)
    {
      return false;
    }

    _ship['name'] = name;
    _ship['totalPrice'] = totalPrice;
    _ship['qty'] = qty;
    _ship['notes'] = notes;

    return true;
  }
}

num numParse(String text, int places) {
  if(text == null || text.isEmpty)
  {
    return 0.0;
  }
  return ((num.parse(text.trim())*100).roundToDouble())/100;
}