class DownloadModel {
  DownloadModel({
    this.id,
    this.api,
    this.vid,
    this.tid,
    this.type,
    this.name,
    this.pic,
    this.url,
    this.fileId,
    this.status,
    this.progress,
    this.savePath,
  });

  DownloadModel.fromJson(dynamic json) {
    id = json['id'] as int?;
    api = json['api'] as String?;
    vid = json['vid'] as String?;
    tid = json['tid'] as String?;
    type = json['type'] as String?;
    name = json['name'] as String?;
    pic = json['pic'] as String?;
    url = json['url'] as String?;
    fileId = json['fileId'] as String?;
    if (json['status'] != null) {
      status = DownloadStatus.values[json['status'] as int];
    }
    progress = json['progress'] as double?;
    savePath = json['savePath'] as String?;
  }

  int? id;
  String? api; // 视频源API地址
  String? vid; // 视频ID
  String? tid; // 分类ID
  String? type; // 分类名称
  String? name; // 标题名
  String? pic; // 缩略图
  String? url; // 下载地址

  String? fileId; // 文件保存ID
  DownloadStatus? status; // 下载状态
  double? progress; // 下载进度  0~1
  String? savePath; // 保存路径

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['api'] = api;
    data['vid'] = vid;
    data['tid'] = tid;
    data['type'] = type;
    data['name'] = name;
    data['pic'] = pic;
    data['url'] = url;
    data['fileId'] = fileId;
    data['status'] = status?.index;
    data['progress'] = progress;
    data['savePath'] = savePath;
    return data;
  }
}

/// 下载状态
enum DownloadStatus {
  // 不需要下载
  none,
  // 等待下载
  waiting,
  // 正在下载
  running,
  // 下载成功
  success,
  // 下载失败
  fail,
}
