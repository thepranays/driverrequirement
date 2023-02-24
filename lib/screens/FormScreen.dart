import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverrequirements/constants/constants.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FormScreen extends StatefulWidget {
  const FormScreen({Key? key}) : super(key: key);

  @override
  State<FormScreen> createState() => _FormScreenState();
}

//Adding new driver request to database
final db = FirebaseFirestore.instance;
Future<void> addNewDriverRequestToDB(Map<String,String> data) async{
  // int timestamp = DateTime.now().millisecondsSinceEpoch;
  db.collection(AppConstants.driverRequestCollec).add(data);
 
}



class _FormScreenState extends State<FormScreen> {
  final TextEditingController _fromLocation =  TextEditingController();
  final TextEditingController _toLocation =  TextEditingController();
  var dropDownValue; //default value of vehicle

  //On Submission of form
  Future<void> submitForm() async{
    //Form Validation
    if(_fromLocation.text=="" || _toLocation.text==""){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill details")));
      return;
    }
    if(dropDownValue==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a vehicle")));
      return;
    }

    Map<String,String>data = {
      "from":_fromLocation.text.toUpperCase(),
      "to":_toLocation.text.toUpperCase(),
      "vehicle":"🚗"+dropDownValue,
    };


    //sending http request to backend server to deliver request notification to all devices subscribed to drivereq
   var response = await http.post(Uri.parse("http://${AppConstants.serverIp}/send-driverreq"),
    headers: {
      "Content-Type":"application/json",
    },
    body: jsonEncode(data));
    final resData = jsonDecode(response.body);

    //show snackbar when driver requested
    final snackBar = SnackBar(
      content: Text(resData["message"]),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);


    //Add new request entry to database
    addNewDriverRequestToDB(data);

    //clear textediting controllers
    _toLocation.clear();
    _fromLocation.clear();
  }

  @override
  Widget build(BuildContext context) {
      return GestureDetector( // to close keyboard when tapped outside form field
        onTap: ()=>FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(),
          body:
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextFormField(
                    decoration:const InputDecoration(labelText:"FROM"
                        ,labelStyle:TextStyle(color:Colors.black)),

                    controller:_fromLocation ,maxLength:20,),

                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.15,
                    height: MediaQuery.of(context).size.width*0.15,

                      child:
                     Material(
                        elevation: 6,
                        shadowColor: Colors.black,
                        borderOnForeground: true,

                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          child: Padding(padding: const EdgeInsets.all(3),child:Row(
                            children: const [
                              Icon(Icons.arrow_downward),
                              Icon(Icons.arrow_upward),
                            ],
                          )),
                          onTap: (){
                            setState(() {
                              String temp = _fromLocation.text;
                              _fromLocation.text = _toLocation.text;
                              _toLocation.text=temp;
                            });
                          },
                        ),
                      ),
        ),

                  TextFormField(decoration:const InputDecoration(labelText:"TO"
                      ,labelStyle:TextStyle(color:Colors.black)),
                    controller:_toLocation ,maxLength:20,),
                  dropDownOption(context),
                  const SizedBox(height: 10,),
                  ElevatedButton(onPressed: (){
                    submitForm();

                  }, child:const Text("Request Driver"))

                ],
              ),
            ),
          )

        ),
      );

  }

  @override
  void dispose() {
    //To avoid memory leak
    _fromLocation.dispose();
    _toLocation.dispose();
    super.dispose();
  }


  //Drop down Input Option widget
  Widget dropDownOption(BuildContext context) {
    return Container(
      padding:const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border:Border.all(color:Colors.black,width: 2)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropDownValue,
          elevation: 3,
          items: <String>['Car', 'Bike', 'Truck']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style:const TextStyle(fontSize: 30),
              ),
            );
          }).toList(),
          hint: const Text(
            "Please choose a vehicle",
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          onChanged: (String? newValue) {
            setState(() {
              dropDownValue = newValue!; //to set display value to selected option
            });
          },
        ),
      ),
    );

  }

}



