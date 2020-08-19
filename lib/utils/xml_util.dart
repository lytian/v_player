import 'package:v_player/models/category_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:xml/xml.dart' as xml;

class XmlUtil {
  static List<CategoryModel> parseCategoryList(String xmlStr) {
    List<CategoryModel> list = [];

    final document = xml.parse(xmlStr);
    final types = document.findAllElements('ty');
    types.forEach((node) {
      list.add(CategoryModel(id: node.getAttribute('id'), name: node.text));
    });

    return list;
  }

  static List<VideoModel> parseVideoList(String xmlStr) {
    List<VideoModel> list = [];

    final document = xml.parse(xmlStr);
    final videos = document.findAllElements('video');
    videos.forEach((node) {
      list.add(VideoModel(
        id: getNodeText(node, 'id'),
        tid: getNodeText(node, 'tid'),
        name: getNodeCData(node, 'name'),
        type: getNodeText(node, 'type'),
        pic: getNodeText(node, 'pic') ?? '',
        lang: getNodeText(node, 'lang'),
        area: getNodeText(node, 'area'),
        year: getNodeText(node, 'year'),
        last: getNodeText(node, 'last'),
        state: getNodeText(node, 'state'),
        note: getNodeCData(node, 'note'),
        actor: getNodeCData(node, 'actor'),
        director: getNodeCData(node, 'director'),
        des: getNodeCData(node, 'des')
      ));
    });

    return list;
  }

  static VideoModel parseVideo(String xmlStr) {
    final document = xml.parse(xmlStr);
    final video = document.findAllElements('video').first;
    if (video == null) return null;
    List<Anthology> anthologies = [];
    String str = getNodeCData(video.findElements('dl').first, 'dd');
    if (str != null) {
      str.split('#').forEach((s) {
        if (s.indexOf('\$') > -1) {
          anthologies.add(Anthology(name: s.split('\$')[0], url: s.split('\$')[1]));
        } else {
          anthologies.add(Anthology(name: null, url: s));
        }
      });
    }
    String stateStr = getNodeText(video, 'state');
    return VideoModel(
      id: getNodeText(video, 'id'),
      tid: getNodeText(video, 'tid'),
      name: getNodeCData(video, 'name'),
      type: getNodeText(video, 'type'),
      pic: getNodeText(video, 'pic'),
      lang: getNodeText(video, 'lang'),
      area: getNodeText(video, 'area'),
      year: getNodeText(video, 'year'),
      last: getNodeText(video, 'last'),
      state: getNodeText(video, 'state'),
      note: getNodeCData(video, 'note'),
      actor: getNodeCData(video, 'actor'),
      director: getNodeCData(video, 'director'),
      des: getNodeCData(video, 'des'),
      anthologies: anthologies
    );
  }

  static String getNodeText(xml.XmlElement node, String name) {
//    if (node == null) return null;
    final elements = node.findElements(name);
    if (elements.isEmpty || elements.first == null) return null;
    return elements.first.text;
  }

  static String getNodeCData(xml.XmlElement node, String name) {
    if (node == null) return null;
    final elements = node.findElements(name);
    if (elements.isEmpty || elements.first == null) return null;
    final children = node.findElements(name).first.children;
    if (children.isEmpty || children.first == null) return null;
    return children.first.text;
  }
}