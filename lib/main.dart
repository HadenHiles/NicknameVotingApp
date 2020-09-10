import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NickNames',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 20, 52, 90),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nickname Votes'),
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _newName,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();

          return _buildList(context, snapshot.data.documents);
        });
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(record.name),
              Text(record.votes.toString()),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: () => Firestore.instance.runTransaction(
              (transaction) async {
                await transaction.delete(record.reference);

                final snackBar = SnackBar(
                  content: Text('Name deleted'),
                  backgroundColor: Color.fromARGB(255, 20, 52, 90),
                );

                Scaffold.of(context).showSnackBar(snackBar);
              },
            ),
          ),
          // Quick for simple increment
          // onTap: () => record.reference.updateData(
          //   {'votes': FieldValue.increment(1)},
          // ),
          onTap: () => Firestore.instance.runTransaction((transaction) async {
            final freshSnapshot = await transaction.get(record.reference);
            final fresh = Record.fromSnapshot(freshSnapshot);

            await transaction
                .update(record.reference, {'votes': fresh.votes + 1});
          }),
          onLongPress: () =>
              Firestore.instance.runTransaction((transaction) async {
            await transaction.update(record.reference, {'votes': 0});
          }),
        ),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  // Create a text controller and use it to retrieve the current value of the TextField.
  final nameFieldController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameFieldController.dispose();
    super.dispose();
  }

  void _newName() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('Add Nickname')),
            body: Column(
              children: <Widget>[
                FormBuilder(
                  key: _formKey,
                  initialValue: {
                    'name': 'Sir rocks a lot',
                    'accept_terms': false,
                  },
                  autovalidate: true,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        controller: nameFieldController,
                        decoration: InputDecoration(labelText: "Name"),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    RaisedButton(
                      child: Text("Add"),
                      onPressed: () {
                        Firestore.instance.collection('name').add({
                          'name': nameFieldController.text.toString(),
                          'votes': 0
                        });

                        nameFieldController.value = TextEditingValue(text: '');

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class Record {
  final String name;
  final int votes;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$votes>";
}
