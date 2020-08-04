import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/download_model.dart';
import 'package:v_player/models/source_model.dart';

class DBHelper {
  static DBHelper _instance;
  factory DBHelper() =>_getInstance();
  Database _db;

  /* 公用列 */
  final String _columnId = 'id';
  final String _columnName = 'name';
  final String _columnUrl = 'url';
  final String _columnType = 'type';

  /* 视频资源表 */
  final String _sourceTableName = 'table_source';
  final String _columnHttpApi = 'httpApi';
  final String _columnHttpsApi = 'httpsApi';

  /* 下载视频表 */
  final String _downloadTableName = 'table_download_video';
  final String _columnApi = 'api';
  final String _columnVid = 'vid';
  final String _columnTid = 'tid';
  final String _columnPic = 'pic';
  final String _columnFileId = 'fileId';
  final String _columnStatus = 'status';
  final String _columnProgress = 'progress';
  final String _columnCollected = 'collected';
  final String _columnSavePath = 'savePath';

  List<String> _allSourceColumn;
  List<String> _allDownloadColumn;
  
  DBHelper._();

  static DBHelper _getInstance() {
    if (_instance == null) {
      _instance = DBHelper._();
      _instance.initDb();
    }
    return _instance;
  }

  initDb() async {
    _allDownloadColumn = [_columnId, _columnApi, _columnTid, _columnType, _columnName, _columnPic, _columnUrl, _columnFileId, _columnStatus, _columnProgress, _columnCollected, _columnSavePath];
    _allSourceColumn = [_columnId, _columnName, _columnUrl, _columnType, _columnHttpApi, _columnHttpsApi];

    String databasesPath  = await getDatabasesPath();
    String path = join(databasesPath, Constant.key_db_name);
    _db = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      // 创建资源表
      await db.execute('''
        create table $_sourceTableName (
          $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $_columnType VARCHAR (64),
          $_columnName TEXT not null,
          $_columnUrl TEXT not null,
          $_columnHttpApi TEXT not null,
          $_columnHttpsApi TEXT
        )
      ''');
      // 创建下载表
      await db.execute('''
        create table $_downloadTableName (
          $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $_columnApi VARCHAR (64) not null, 
          $_columnVid VARCHAR (32) not null, 
          $_columnTid VARCHAR (32),
          $_columnType VARCHAR (64),
          $_columnName TEXT,
          $_columnPic TEXT not null,
          $_columnUrl TEXT not null,
          $_columnFileId TEXT,
          $_columnStatus	INTEGER NOT NULL DEFAULT 0,
	        $_columnProgress	REAl NOT NULL DEFAULT 0,
          $_columnCollected INTEGER NOT NULL DEFAULT 0,
          $_columnSavePath TEXT
        )
      ''');
    });
  }

  /// 插入资源
  Future<int> insertSource(SourceModel model) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    if (model == null) return 0;
    // 去掉自带的ID，让数据库自增
    model.id = null;
    return await _db.insert(_sourceTableName, model.toJson());
  }

  /// 批量 插入资源
  Future<int> insertBatchSource(List<SourceModel> list) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    final batch = _db.batch();
    list.forEach((model) {
      // 去掉自带的ID，让数据库自增
      model.id = null;
      batch.insert(_sourceTableName, model.toJson());
    });
    final result = await batch.commit();
    return result.length;
  }

  /// 插入下载
  Future<int> insertDownload(DownloadModel model) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    return await _db.insert(_downloadTableName, model.toJson());
  }

  /// 根据ID删除资源
  Future<int> deleteSourceById(int id) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    print(id);
    return await _db.delete(_sourceTableName, where: '$_columnId = ?', whereArgs: [id]);
  }

  /// 根据ID删除下载
  Future<int> deleteDownloadById(int id) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    return await _db.delete(_downloadTableName, where: '$_columnId = ?', whereArgs: [id]);
  }

  /// 根据ID集删除下载
  Future<int> deleteDownloadByIds(List<int> ids) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    return await _db.delete(_downloadTableName, where: '$_columnId in (${ids.join(',')})', whereArgs: []);
  }

  /// 根据ID修改资源
  Future<int> updateSourceById(SourceModel model) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    if (model == null || model.id == null) return 0;

    return await _db.update(_sourceTableName, model.toJson(),
        where: '$_columnId = ?', whereArgs: [model.id]);
  }

  /// 根据ID修改下载
  Future<int> updateDownloadById(DownloadModel model) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    if (model == null || model.id == null) return 0;

    return await _db.update(_downloadTableName, model.toJson(),
        where: '$_columnId = ?', whereArgs: [model.id]);
  }

  /// 根据URL修改下载进度
  Future<int> updateDownloadByUrl(String url, { double progress, DownloadStatus status }) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }

    Map<String, dynamic> maps = {};
    if (progress != null) {
      maps["progress"] = progress;
    }
    if (status != null) {
      maps["status"] = status.index;
    }

    return await _db.update(_downloadTableName, maps, where: '$_columnUrl = ?', whereArgs: [url]);
  }

  /// 根据ID获取资源
  Future<SourceModel> getSourceById(int id) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    List<Map> maps = await _db.query(_sourceTableName,
        columns: _allSourceColumn,
        where: '$_columnId = ?',
        whereArgs: [id]);

    if (maps.length > 0) {
      return SourceModel.fromJson(maps.first);
    }
    return null;
  }

  /// 根据ID获取下载
  Future<DownloadModel> getDownloadById(int id) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    List<Map> maps = await _db.query(_downloadTableName,
        columns: _allDownloadColumn,
        where: '$_columnId = ?',
        whereArgs: [id]);

    if (maps.length > 0) {
      return DownloadModel.fromJson(maps.first);
    }
    return null;
  }

  /// 根据视频URl获取下载
  Future<DownloadModel> getDownloadByUrl(String url) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    List<Map> maps = await _db.query(_downloadTableName,
        columns: _allDownloadColumn,
        where: '$_columnUrl = ?',
        whereArgs: [url]);

    if (maps.length > 0) {
      return DownloadModel.fromJson(maps.first);
    }
    return null;
  }

  /// 根据条件获取资源列表
  Future<List<SourceModel>> getSourceList({ String type, String name }) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    List<String> whereStr = [];
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereStr.add('$_columnType = ?');
      whereArgs.add(type);
    } else if (name != null) {
      whereStr.add('$_columnName like %?%');
      whereArgs.add(name);
    }
    whereArgs.add('status != ${DownloadStatus.NONE.index}');

    List<Map> maps;
    if (whereStr.isEmpty) {
      maps = await _db.query(_sourceTableName,
          columns: _allSourceColumn,
          orderBy: '$_columnId ASC',
      );
    } else {
      maps = await _db.query(_sourceTableName,
          columns: _allSourceColumn,
          where: whereStr.join(", "),
          whereArgs: whereArgs,
          orderBy: '$_columnId ASC',
      );
    }
    if (maps.length > 0) {
      return maps.map((json) => SourceModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<DownloadModel>> getDownloadList({int pageNum = 0, int pageSize = 100, DownloadStatus status, String url, String savePath, String name}) async {
    if (_db == null || !_db.isOpen) {
      await _instance.initDb();
    }
    List<String> whereStr = [];
    List<dynamic> whereArgs = [];

    if (url != null) {
      whereStr.add('$_columnUrl = ?');
      whereArgs.add(url);
    } else if (savePath != null) {
      whereStr.add('$_columnSavePath = ?');
      whereArgs.add(savePath);
    } else if (status != null) {
      whereStr.add('$_columnStatus = ?');
      whereArgs.add(status.index);
    } else if (name != null) {
      whereStr.add('$_columnName like %?%');
      whereArgs.add(name);
    }

    List<Map> maps;
    if (whereStr.isEmpty) {
      maps = await _db.query(_downloadTableName,
        columns: _allDownloadColumn,
        orderBy: '$_columnId DESC',
        limit: pageSize,
        offset: pageNum * pageSize);
    } else {
      maps = await _db.query(_downloadTableName,
        columns: _allDownloadColumn,
        where: whereStr.join(", "),
        whereArgs: whereArgs,
        orderBy: '$_columnId DESC',
        limit: pageSize,
        offset: pageNum * pageSize);
    }
    if (maps.length > 0) {
      return maps.map((json) => DownloadModel.fromJson(json)).toList();
    }
    return [];
  }

  /// 关闭数据库
  Future close() async {
    if (_db != null && _db.isOpen) {
      await _db.close();
    }
  }
}