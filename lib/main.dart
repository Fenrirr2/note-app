import 'package:floating_logger/floating_logger.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DioLogger.instance.addListInterceptor(
    [
      InterceptorsWrapper(
        onResponse: (response, handler) {
          // add interceptor condition
          print('Custom onResponse interceptor');
          handler.next(response);
        },
        onError: (error, handler) {
          // add interceptor condition
          print('Custom onError interceptor');
          handler.next(error);
        },
      ),
      PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
          filter: (options, args) {
            // don't print requests with uris containing '/posts'
            if (options.path.contains('/posts')) {
              return false;
            }
            // don't print responses with unit8 list data
            return !args.isResponse || !args.hasUint8ListData;
          })
    ],
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NoteScreen(),
    );
  }
}

class NoteScreen extends StatefulWidget {
  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _notes = [];
  String? name;

  Future<void> fetchGlobalTime() async {
    try {
      var response =
          await DioLogger.instance.get('https://api.genderize.io?name=james');
      setState(() {
        name = response.data['name'];
      });
    } catch (e) {
      print('Error fetching time: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGlobalTime();
  }

  final ValueNotifier<bool> isShow = ValueNotifier(true);
  @override
  Widget build(BuildContext context) {
    return FloatingLoggerControl(
      // isShow: isShow,
      // widgetItemBuilder: (index, data) {
      //   print('data : $data');
      //   return const SizedBox.shrink();
      // },
      child: Scaffold(
        appBar: AppBar(title: Text("Simple Note App")),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: "Enter Note",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (_controller.text.isNotEmpty) {
                          _notes.add(_controller.text);
                          _controller.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            Text(name != null ? "Your Name: $name" : "Loading global time..."),
            Expanded(
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_notes[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _notes.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
