import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  static const String _uri =
      'mongodb+srv://yourusername:yourpassword@yourcluster.mongodb.net/?retryWrites=true&w=majority&appName=yourAppName';
  late final Db _db;
  late final DbCollection _collection;

  Future<void> connect(String recordingType) async {
    _db = await Db.create(_uri);
    await _db.open();
    _collection =
        _db.collection(recordingType == 'stationary' ? 'stationary' : 'path');
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    await _collection.insert(data);
  }

  Future<void> close() async {
    await _db.close();
  }
}
