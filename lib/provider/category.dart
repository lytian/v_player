import 'package:flutter/widgets.dart';
import 'package:v_player/models/category_model.dart';
import 'package:v_player/utils/http_util.dart';

class CategoryProvider with ChangeNotifier {

  int _categoryIndex = 0;
  List<CategoryModel> _categoryList = [];

  int get categoryIndex => _categoryIndex;
  List<CategoryModel> get categoryList => _categoryList;


  void setCategoryIndex(int index) {
    _categoryIndex = index;
    notifyListeners();
  }

  Future<void> getCategoryList() async {
    final List<CategoryModel> list = await HttpUtil().getCategoryList();
    _categoryList = [CategoryModel(id: '', name: '最新')] + list;
    notifyListeners();
  }
}
