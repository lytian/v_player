import 'package:flutter/widgets.dart';
import 'package:v_player/models/category_model.dart';
import 'package:v_player/utils/http_utils.dart';

class CategoryProvider with ChangeNotifier {

  int _categoryIndex = 0;
  List<CategoryModel> _categoryList = [];

  int get categoryIndex => _categoryIndex;
  List<CategoryModel> get categoryList => _categoryList;


  void setCategoryIndex(int index) {
    _categoryIndex = index;
    notifyListeners();
  }

  void getCategoryList() async {
    List<CategoryModel> list = await HttpUtils.getCategoryList();
    _categoryList = [CategoryModel(id: '', name: '最近更新')] + list;
    notifyListeners();
  }
}