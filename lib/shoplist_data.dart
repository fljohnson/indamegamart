import 'dart:async';
//import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

bool debugging = true;
bool initialLoadDone = false;
Database _database;
int dbversion = 1;
var loadCallback; // = null;
class Shoplist {
  int id;
  String name;
  String date; //default is today
  //items (one-to-many)
  List<RelListItem> _cachedItemList = [];

  static List<Shoplist> _linearLists = [];
  static Map<int,Shoplist> _lists = Map();

  num plannedTotal = 8.0;
  num currentTotal = 0.0;
  bool isBlank = true;

  bool get overage => (currentTotal - plannedTotal >= 0.01);

  static Future<void> loadLists({int ith=-1}) async
  {
    _lists.clear();
    _linearLists.clear();
    /*
    List<Map> rows = await _database.rawQuery(
        "SELECT * FROM List ORDER BY id"
    );
    */
    List<Map> rows = await _database.transaction((txn) async {
      return await txn.rawQuery(
          "SELECT * FROM List ORDER BY id"
      );
    });
    int totalct=rows.length;
    for(int i=0;i<totalct;i++)
    {
      Shoplist daList = Shoplist(rows[i]["id"],rows[i]["name"],rows[i]["isoDate"],reloading: true);
      _lists[daList.id]=daList;
      _linearLists.add(daList);
      if(_linearLists.length >totalct )
      {
        print("ALERT");
      }
    }
    if(ith >=0 && ith < _linearLists.length)
    {
      await _linearLists[ith].load();
    }
    /*
    rows.forEach((row){
      var daList = Shoplist(row["id"],row["name"],row["isoDate"],reloading: true);
      _lists[daList.id]=daList;
      _linearLists.add(daList);
      if(_linearLists.length >12 )
        {
          print("ALERT");
        }
    });
    */
    /*
    List<int> kets = _lists.keys.toList();
    kets.sort();
    _linearLists = [];
    kets.forEach((k){
      _linearLists.add(_lists[k]);
    });
    */
  }

  void fillIfNeeded() async
  {
    if(!isBlank && _cachedItemList.length == 0)
    {

      /*
      String head = "$id:";

      currentTotal = 0.0;
      _listToItem.keys.forEach((suspectKey){
        if(suspectKey.startsWith(head) && _listToItem[suspectKey].visible)
        {
          _cachedItemList.add(_listToItem[suspectKey]);

          if(_listToItem[suspectKey].gotIt)
          {
            currentTotal += _listToItem[suspectKey].totalprice;
          }
        }
      });
      */
      //breaking with pattern by not holding all RelListItems in RAM
      //List<Map> rows = await _database.rawQuery("SELECT * FROM ListToItem WHERE visible = 1 AND listID = ?",[id]);
      List<Map> rows = await _database.transaction((txn) async {
        return txn.rawQuery("SELECT * FROM ListToItem WHERE visible = 1 AND listID = ?",[id]);
      });
      int totalct = rows.length;
      if(totalct > 0)
        {
          print("97 YES! $totalct");
        }
      currentTotal = 0.0;
      for(int i=0;i<totalct;i++)
      {
        //int listid,int itemid,num qty,num price,String notes
          RelListItem present = RelListItem(
              rows[i]['listID'],
              rows[i]['itemID'],
              rows[i]['qty'],
              rows[i]['price'],
              rows[i]['notes'],
              gotIt:(rows[i]['inCart'] == 1)
          );
print("111 add");
          _cachedItemList.add(present);
          if(present.gotIt)
          {
            currentTotal += present.totalprice;
          }
      }

    }


  }

  Shoplist(int i, String s, String t,{bool reloading=false}){
    id = i;
    name = s.trim();
    date =t.trim();


    if(!reloading) {
      addList(this).then((newId) {
        this.id = newId;
        print("installed $id: $name $date");
      });
    }

  }

  int _getListLength() {
    fillIfNeeded();

    return _cachedItemList.length;
  }
  get length => _getListLength();

  static Future<List<Shoplist>> getLists() async{
    await loadLists();
    return _linearLists;
  }

  static Future<Shoplist> getIthList(int index) async {
    await loadLists(ith:index);
    return _linearLists[index];
  }

  static Future<Shoplist> findListByName(String soughtName) async
  {
    Shoplist rv;
    String newvalue = soughtName.trim();
    //List<Map> fetchedList = await _database.rawQuery('SELECT id FROM List where name =? ',[newvalue]);
    List<Map> fetchedList = await _database.transaction((txn) async {
      return await txn.rawQuery('SELECT id FROM List where name =? ',[newvalue]);
    });

    if(fetchedList.isEmpty)
    {
      return rv;
    }
    rv = _lists[fetchedList[0]['id']];
    return rv;
  }
  static Future<Shoplist> newList(String newvalue) async{
    Shoplist rv;
    if(newvalue.isEmpty)
      {
        return rv;
      }

    rv = await findListByName(newvalue);

    if(rv == null)
    {
      rv = Shoplist(_lists.length,newvalue,isoDate(DateTime.now()));
      _lists[rv.id]=(rv);
    }
    return rv;
  }

  RelListItem getIthItem(int index) {

    fillIfNeeded();
    if(index<0 || index >= _cachedItemList.length)
    {
      return null;
    }
    return _cachedItemList[index];
  }

  void primeReload() {
    _cachedItemList.clear();
  }

  String strPlannedTotal() {
    fillIfNeeded();
    return numToString(plannedTotal,2);
  }

  strCurrentTotal() {
    fillIfNeeded();
    return numToString(currentTotal,2);
  }

  static Future<void> createTable(Database db) async{
      await db.execute(
          'CREATE TABLE List (id INTEGER PRIMARY KEY, name TEXT, isoDate TEXT)'
      );
      await db.execute(
          'CREATE INDEX List_name on List (name)'
      );
  }

  static Future<int> addList(Shoplist toSave) async {
    /*
    int rv = await _database.rawInsert(
      'INSERT INTO List (name,isoDate) values  (?,?)',
      [toSave.name,toSave.date]
    );
    */
    int rv = await _database.transaction((txn) async {
      return await txn.rawInsert(
          'INSERT INTO List (name,isoDate) values  (?,?)',
          [toSave.name,toSave.date]
      );
    });
    return rv;
  }

  Future<void>load() async{

    //List<Map> rows = await _database.rawQuery("SELECT * FROM ListToItem WHERE visible = 1 AND listID = ?",[id]);
    List<int> itemSeek = [];
    await _database.transaction((txn) async {
      List<Map> rows = await txn.rawQuery("SELECT * FROM ListToItem WHERE visible = 1 AND listID = ?",[id]);
      _cachedItemList.clear();

      int totalct = rows.length;
      if(totalct > 0)
      {
        print("234 YES! $totalct");
      }
      isBlank = (totalct == 0);
      currentTotal = 0.0;
      for(int i=0;i<totalct;i++)
      {
        itemSeek.add(rows[i]['itemID']);
        //int listid,int itemid,num qty,num price,String notes
        RelListItem present = RelListItem(
            rows[i]['listID'],
            rows[i]['itemID'],
            rows[i]['qty'],
            rows[i]['price'],
            rows[i]['notes'],
            gotIt:(rows[i]['inCart'] == 1)
        );
        print("retrieved ListToItem ${rows[i]['listID']},${rows[i]['itemID']},${rows[i]['qty']},${rows[i]['price']},${rows[i]['notes']}");

        print("251 add");
        _cachedItemList.add(present);
        if(present.gotIt)
        {
          currentTotal += present.totalprice;
        }
      }

    });

    await Shopitem.reload(itemSeek);

  }
}

String isoDate(DateTime dateTime) {
  return DateFormat("yyyy-MM-dd").format(dateTime);
}

class Shopitem {
  int id;
  String name;
//price_history (one-to-many)

  Shopitem(int itemID,String itemName)
  {
    id=itemID;
    name = itemName;



  }

  static Future<int> addItem(Shopitem toSave) async {
    /*
    int rv = await _database.rawInsert(
        'INSERT INTO Item (name) values  (?)',
        [toSave.name]
    );
    */
    int rv = await _database.transaction((txn) async {
      return await txn.rawInsert(
          'INSERT INTO Item (name) values  (?)',
          [toSave.name]
      );
    });
    return rv;
  }

  static Map<int,Shopitem> _items = Map();

  //returns empty list in "no match" and "input too short" situations
  static Future<List<String>> getItemSuggestions(String suspect) async
  {
    List<String> hits = [];
    if(suspect.trim().length<4) //4 as minimum seems reasonable in this application
    {
      return hits;
    }
    /*
    //the implementation will change when the DB gets here
    RegExp search = RegExp(suspect.trim().replaceAll(" ", ".*"),caseSensitive:false);
    _items.forEach((maybe){
      if(search.hasMatch(maybe.name))
        {
          hits.add(maybe.name);
        }
    });
    //NB:SQL will make the sorting a snap
    */
    /*
    List<Map> rows = await _database.rawQuery("SELECT name FROM Item where name LIKE ? ORDER BY name",
      ["%"+suspect.trim().replaceAll(" ", "%")+"%"]
    );
    */
    List<Map> rows = await _database.transaction((txn) async{
      return await txn.rawQuery("SELECT name FROM Item where name LIKE ? ORDER BY name",
          ["%"+suspect.trim().replaceAll(" ", "%")+"%"]
      );
    });
    int totalct = rows.length;
    for(int i=0;i<totalct;i++)
    {
      hits.add(rows[i]["name"]);
    }

    return hits;
  }

  static Future<Shopitem> findItemByName(String suspectName) async
  {

/*
    _items.forEach((subject){
      if(subject.name == itemname)
      {
        rv=subject;
      }
    });
    */
/*
    List<Map> rows = await _database.rawQuery(
        "SELECT id FROM Item WHERE name = ? ORDER BY id",
      [suspectName.trim()]
    );
*/
    List<Map> rows = await _database.transaction((txn) async {
      return await txn.rawQuery(
          "SELECT id FROM Item WHERE name = ? ORDER BY id",
          [suspectName.trim()]
      );
    });
    if(rows.length == 0)
    {
      return null;
    }
    return _items[rows[0]['id']];

  }
  static Future<Shopitem> newItem(int listID, String preitemname,num price,num qty, String notes) async
  {
    String itemname = preitemname.trim();
    Shopitem rv;
    if(itemname.isEmpty)
    {
      return rv;
    }

    rv = await findItemByName(itemname);

    if(rv == null)
    {
      rv = new Shopitem(_items.length,itemname);
      rv.id = await addItem(rv);
      _items[rv.id]=(rv);
      print("persist Shopitem ${rv.id} ${rv.name}");

      /*
      addItem(this).then((newID){
        this.id = newID;
        print("persist Shopitem $id $name");
        if(id == 2)
        {
          print("Wake");
        }
      });
      */


    }
    print("calling hook...$listID,${rv.id},${rv.name}");
    await hookToList(listID,rv,qty,price,notes);
    return rv;
  }

  static Shopitem getItem(int itemID) {
    Shopitem rv;
    if(_items.containsKey(itemID))
    {
      return _items[itemID];
    }
    /*
    _items.forEach((suspect){
      if(suspect.id == itemID)
        {
          rv = suspect;
        }
    });
    */
    return rv;
  }

  static Future<void> createTable(Database db) async{
    await db.execute(
        'CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)'
    );
    await db.execute(
        'CREATE INDEX Item_name on Item (name)'
    );
  }

  static Future<void> reload(List<int> idlist) async{
    _items.clear();
    if(idlist.isEmpty)
      {
        return;
      }
    String bund = idlist.join(",");
    //List<Map> rows = await _database.rawQuery("SELECT * FROM Item where id in ( $bund )");
    List<Map> rows = await _database.transaction((txn) async {
      var rv = await txn.rawQuery("SELECT * FROM Item where id in ( $bund )");
      return rv;
    });
    int totalcount = rows.length;
    for(int i=0;i<totalcount;i++)
      {
        Shopitem present = Shopitem(rows[i]["id"],rows[i]["name"]);
        _items[present.id] = present;
      }
  }
}

class RelListItem {
  //list_id,item_id crammed into a String key
  int listID;
  int itemID;
  num totalprice;
  num qty;

  bool visible = true;
  bool gotIt = false;
  String notes;


  RelListItem(int listid,int itemid,num qty,num price,String notes, {bool gotIt=false})
  {
    listID = listid;
    itemID = itemid;
    this.totalprice = price;
    this.qty = qty;
    this.notes = notes;
    if(gotIt)
    {
      this.gotIt = gotIt;
    }
  }

  String get strQty => numToString(qty,2);

  String get name => Shopitem._items[itemID].name;

  String get strPrice => numToString(totalprice, 2);

  get strUnitprice => numToString(totalprice/qty,2);

  static Future<void> createTable(Database db) async{
    await db.execute(
        'CREATE TABLE ListToItem (id INTEGER PRIMARY KEY, listID INTEGER, itemID INTEGER, visible INTEGER DEFAULT 1, inCart INTEGER DEFAULT 0,qty REAL DEFAULT 1, price REAL, notes TEXT)'
    );
    await db.execute(
        'CREATE INDEX LI_list on ListToItem (listID)'
    );

  }


}

String numToString(num qty, int places) {

  int sec = (qty*pow(10,places)).round();
  num fin = sec/pow(10,places);
  List<String> proto = ("$fin").split(".");
  if(proto.length == 1)
    {
      proto.add("0");
    }
  while(proto[1].length < places)
    {
      proto[1] += "0";
    }
  return proto.join(".");
}


//Map<String,RelListItem> _listToItem = Map(); //seems to be okay to ditch

Future<void> updateItemStatus(RelListItem subject) async {
  /*
  await _database.rawUpdate("UPDATE ListToItem SET visible = ?, inCart = ? WHERE listID = ? and itemID =? ",
      [subject.visible ? 1:0, subject.gotIt ?1:0,subject.listID,subject.itemID]
  );
  */
  await _database.transaction((txn) async {

    await txn.rawUpdate("UPDATE ListToItem SET visible = ?, inCart = ? WHERE listID = ? and itemID =? ",
        [subject.visible ? 1:0, subject.gotIt ?1:0,subject.listID,subject.itemID]
    );
  });
}

Future<void> hookToList(int listID, Shopitem rv, num qty, num price, String notes) async{
  //now things get weird

  print("starting hook...$listID,${rv.id},${rv.name}");
  /*
  List<Map> extant = await _database.rawQuery("SELECT * FROM ListToItem WHERE listID = ? and itemID = ?",
    [listID,rv.id]
  );
  if(extant.isNotEmpty)
  {
    await _database.rawUpdate("UPDATE ListToItem SET qty = ?, price = ?, notes = ? WHERE id = ?",
      [qty,price,notes,extant[0]['id']]
    );
    print("Updated relation $listID,${rv.id},$qty,$price,$notes");
  }
  else
  {
    print("About to Insert relation $listID,${rv.id},${rv.name},$qty,$price,$notes");
    await _database.rawInsert("INSERT INTO ListToItem (listID,itemID,qty, price,notes) VALUES(?,?,?,?,?)",
        [listID,rv.id,qty,price,notes]
    );
    print("Inserted relation $listID,${rv.id},${rv.name},$qty,$price,$notes");
  }
*/
  //now even weirder
  await _database.transaction((txn) async {


    List<Map> extant = await txn.rawQuery("SELECT * FROM ListToItem WHERE listID = ? and itemID = ?",
        [listID,rv.id]
    );
    if(extant.isNotEmpty)
    {
      await txn.rawUpdate("UPDATE ListToItem SET qty = ?, price = ?, notes = ? WHERE id = ?",
          [qty,price,notes,extant[0]['id']]
      );
      print("Updated relation $listID,${rv.id},$qty,$price,$notes");
    }
    else
    {
      print("About to Insert relation $listID,${rv.id},${rv.name},$qty,$price,$notes");
      await txn.rawInsert("INSERT INTO ListToItem (listID,itemID,qty, price,notes) VALUES(?,?,?,?,?)",
          [listID,rv.id,qty,price,notes]
      );
      print("Inserted relation $listID,${rv.id},${rv.name},$qty,$price,$notes");
    }
  });
  /*
  String key = "$listID:${rv.id}";
  RelListItem toEdit;
  bool adding;
  if(_listToItem.containsKey(key))
  {
    adding = false;
    toEdit = _listToItem[key];
    toEdit.qty = qty;
    toEdit.totalprice = price;
    toEdit.notes = notes;
    //betting on something pointerriffic
  }
  else
  {
    adding = true;
    toEdit = RelListItem(listID,rv.id,qty,price,notes);
    _listToItem[key] = toEdit;
  }
  */
}

Future<void> _loadListHulls() async
{
  Map<int,Shoplist> mess =
      {
        1: Shoplist(1, "test 1", "2019-01-21",reloading: true),
        2: Shoplist(2, "test 2", "2019-01-23",reloading: true),
        3: Shoplist(3, "test 3", "2019-01-21",reloading: true),
        4: Shoplist(4, "test 4", "2019-01-23",reloading: true),
        5: Shoplist(5, "test 5", "2019-01-21",reloading: true),
        6: Shoplist(6, "test 6", "2019-01-23",reloading: true),
        7: Shoplist(7, "test 7", "2019-01-21",reloading: true),
        8: Shoplist(8, "test 8", "2019-01-23",reloading: true),
        9: Shoplist(9, "test 9", "2019-01-21",reloading: true),
        10: Shoplist(10, "test 10", "2019-01-23",reloading: true),
        11: Shoplist(11, "test 11", "2019-01-21",reloading: true),
        12: Shoplist(12, "test 12", "2019-01-23",reloading: true),
      }
  ;
  mess.forEach((key,value) async {

    int newId = await Shoplist.addList(value);

      value.id = newId;

      Shoplist._lists[value.id] = value;
      print("installed ${value.id}: ${value.name} ${value.date}");

  });

}

Future<void> _loadItems() async
{
  await Shopitem.newItem(1, "beef franks", 3.50, 1,"2 for 7");
  await Shopitem.newItem(2, "5 lbs flour",  1.99,1, null);
  await Shopitem.newItem(2, "lb unsalted butter",  2.99,1, null);
  await Shopitem.newItem(3, "5 lbs russet potatoes", 1.99,1,  null);
  await Shopitem.newItem(1, "4 lbs sugar",  1.99,1, "cookies too");
  await Shopitem.newItem(1, "5 lbs russet potatoes",2.99, 1,  null);
}
void initData() async
{
  print("BEGIN");
  getDatabase().then((nothing)
  {
      initialLoadDone = true;
      print("FINISHED");
      if(loadCallback != null)
      {
        loadCallback();
      }
  });
  /*
  Timer(Duration(seconds:10),
      ((){

        _loadListHulls();
        _loadItems();
        initialLoadDone = true;
        print("FINISHED");
        if(loadCallback != null)
          {
            loadCallback();
          }
      })
  );
*/

}

void addWaker(Null Function() callback) {
  loadCallback = callback;
}

Future<void> getDatabase() async
{
  // Get a location using getDatabasesPath
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'demo.db');
  if(debugging)
  {
    await deleteDatabase(path);
  }


  // open the database
  _database = await openDatabase(path, version: dbversion,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await Shoplist.createTable(db);
        await Shopitem.createTable(db);
        await RelListItem.createTable(db);
      });

  await _loadListHulls();
  await _loadItems();
}