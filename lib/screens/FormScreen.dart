import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverrequirements/constants/constants.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  var dropDownValue; //default value of vehicle

  //On Submission of form
  Future<void> submitForm() async{
    //Form Validation
    if(_fromLocation.text=="" || _toLocation.text=="" || _timeController.text=="" || _dateController.text==""){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill details")));
      return;
    }
    if(dropDownValue==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a vehicle")));
      return;
    }
    String vehicleUrl = "";
    switch(dropDownValue){
      case "Bike":
        vehicleUrl = AppConstants.bikeImage;
        break;
      case "Truck":
        vehicleUrl = AppConstants.truckImage;
        break;
      case "Car":
        vehicleUrl = AppConstants.carImage;
        break;
      default:
        vehicleUrl = AppConstants.carImage;
        break;
    }
    Map<String,String>data = {
      "from":_fromLocation.text.toUpperCase(),
      "to":_toLocation.text.toUpperCase(),
      "vehicle":dropDownValue,
      "imageUrl":vehicleUrl,
      "date":_dateController.text,
      "time":_timeController.text,
      "datetime":_dateController.text+" "+_timeController.text,
      "dist":"123 km" //hardcoded for test purpose

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
    _dateController.clear();
    _timeController.clear();
    setState(() {
      dropDownValue=null;
    });
  }


  //TO PICK A TIME IN INPUT FIELD
  Future<void> pickATime(BuildContext context) async{
    TimeOfDay? pickedTime =  await showTimePicker(
      initialTime: TimeOfDay.now(),
      context: context,
    );

    if(pickedTime != null ){
      DateTime parsedTime = DateFormat.jm().parse(pickedTime.format(context).toString());
      String formattedTime = DateFormat('HH:mm').format(parsedTime);
       //output 14:59:00
      setState(() {
        _timeController.text =formattedTime;
      });
    }
  }

  //TO PICK A DATE-TIME IN INPUT FIELD
Future<void> pickADate(BuildContext context) async {
  DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), //get today's date
      firstDate:DateTime.now(),
      lastDate: DateTime(2101)
  );
  if(pickedDate != null ){
    String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
    setState(() {
      _dateController.text = formattedDate; //set foratted date to TextField value.
    });
  }
}


  //THIS Screen widget
  @override
  Widget build(BuildContext context) {
      return GestureDetector( // to close keyboard when tapped outside form field
        onTap: ()=>FocusScope.of(context).unfocus(),
        child: Scaffold(

          body:SafeArea(child:
            Stack(children: [

              SizedBox(height:MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
                child:const Image(image:AssetImage(AppConstants.formMapBackground),fit:BoxFit.cover,),
              ),
              Center(
                child: Material(
                  elevation: 200,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  ),
                    width: MediaQuery.of(context).size.width*0.87,
                    height: MediaQuery.of(context).size.height*0.9,
                    child:formWidget(),),
                ),
              ),
              Align(alignment: Alignment.topLeft,
                child: IconButton(onPressed: (){
                  Navigator.of(context).pop();

                }, icon:const Icon(Icons.arrow_back)),
              ),
            ],)
            ,)


        ),
      );

  }

  @override
  void dispose() {
    //To avoid memory leak
    _fromLocation.dispose();
    _toLocation.dispose();
    _timeController.dispose();
    _dateController.dispose();
    dropDownValue=null;
    super.dispose();
  }

  //Form Widget
  Widget formWidget(){
    return Container(
      margin:const EdgeInsets.all(20),
      child: RawScrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextFormField(onFieldSubmitted:(string){
                  submitForm();
                },
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

                TextFormField(onFieldSubmitted:(string){
                  submitForm();
                }
                ,decoration:const InputDecoration(labelText:"TO"
                    ,labelStyle:TextStyle(color:Colors.black)),
                  controller:_toLocation ,maxLength:20,),
                TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.calendar_today),
                        labelText: "Enter Date"
                    ),
                    readOnly: true,
                    onTap: ()  {
                            pickADate(context); // to open calendar to select date
                    }
                ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                    icon: Icon(Icons.timer),
                    labelText: "Enter Time" ,
                ),
                readOnly: true,
                onTap:(){
                  pickATime(context);
                }
              ),

                //DROPDOWN
                Padding(padding: const EdgeInsets.only(top:20,bottom: 5),child: dropDownOption(context)),
                const SizedBox(height: 10,),

                //SUBMIT BUTTON
                ElevatedButton(
                    onPressed: (){
                  submitForm();

                }, child:const Text("Request Driver"))

              ],
            ),
          ),
        ),
      ),
    );
  }

  //Drop down Input Option widget
  Widget dropDownOption(BuildContext context) {
    return Container(
      padding:const EdgeInsets.all(2),
      width: MediaQuery.of(context).size.width*0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border:Border.all(color:Colors.black,width: 2)
      ),
      child: DropdownButtonHideUnderline(

        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            isExpanded: true,
            isDense: true,
            value: dropDownValue,
            elevation: 3,
            items: <String>['Car', 'Bike', 'Truck']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            }).toList(),
            hint: const FittedBox( fit: BoxFit.fitWidth,
              child: Text(
                "Please choose a vehicle",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
            onChanged: (String? newValue) {
              setState(() {
                dropDownValue = newValue!; //to set display value to selected option
              });
            },
          ),
        ),
      ),
    );

  }

}



