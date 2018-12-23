import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:screen/screen.dart';


class HomePage extends StatefulWidget{
  @override
  State createState() => new HomePageState();
}

class HomePageState extends State<HomePage>{
  var screen = new Screen();
  String _filePath;
  String status = "Choose a file";

  Future<bool> get screenIsKeptOn async{
    return await Screen.isKeptOn;
  }

  Future<String> get _localPath async{
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _getfilePath() async {
    String fileName;
    try{
      String filePath = await FilePicker.getFilePath(type: FileType.ANY);
      if (filePath == '') {
        return;
      }
      //fileName = basename(File(filePath).path);
      fileName = basename(filePath);
      setState((){this._filePath = filePath; this.status="File chosen: " + fileName;});
    } catch (e) {
      setState((){status = e.toString();});
      print("Error while picking the file: " + e.toString());
    }
  }

  void _decomRouter() {
    if (this._filePath != ""){
      final File fileToExtract = File(_filePath);
      var name = basename(fileToExtract.path);
      if (name.contains("zip") && fileToExtract.lengthSync() < 65536000) {
        _unzipFileSmall(fileToExtract);
      } else if (name.contains("zip") && fileToExtract.lengthSync() > 65536000){
        _unzipFileLarge(fileToExtract);
      } else if (name.contains("bz2")){
        //not implemented
      }
    } else {
        print("not supported");
    }
  }

  _unzipFileSmall(File x) async {
    var name = basename(x.path);
    try {
      setState((){status="Setting screen keep on true\n";});
      if (await screenIsKeptOn == false)
        Screen.keepOn(true);
      setState((){status="reading archive\n";});

      var bytes = x.readAsBytesSync();
      setState((){status="decompressing";});
      var archive = new ZipDecoder().decodeBytes(bytes);

      for (ArchiveFile file in archive) {
        var fileName = file.name;
        if (file.isFile) {
          var data = file.content;
          new File(await _localPath + "/" + name.substring(0, name.length-4) + "/" + fileName)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          new Directory(await _localPath + '/' + basename(x.path) + "/" + fileName)
            ..create(recursive: true);
        }
        setState(() {status = "Success!";});
      }
    } catch (e) {
      setState(() {status = "Error: " + e.toString();});
    } finally {
      if (await screenIsKeptOn == true)
        Screen.keepOn(false);
    }
  }


  _unzipFileLarge(File x) async {
    setState((){status="Setting screen keep on true";});
    if (await screenIsKeptOn == false)
      Screen.keepOn(true);
    setState((){status="reading archive";});


    try {
      var stream = new InputFileStream(x.path);
      var data = stream.readBytes(stream.bufferSize);
      while (data != null){
        // to do
        data = stream.readBytes(stream.bufferSize);
      }


    } catch (e) {
      print(e.toString());
    }

  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("File Manager"),
      ),
      body: Container(
          child: new Center(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new CupertinoButton(
                    //height: 100.0,
                    child: Text("Open File"),
                    color: CupertinoColors.activeBlue,
                    minSize: 40,
                    onPressed: _getfilePath),
                Padding(padding: EdgeInsets.all(8.0)),
                Text("$status",
                  style: TextStyle(fontSize: 18),
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                new CupertinoButton(
                  //height: 100.0,
                  child: Text("Extract"),
                  color: CupertinoColors.activeBlue,
                  onPressed: _decomRouter,
                ),
              ],
            ),
          )
      ),
    );
  }

}