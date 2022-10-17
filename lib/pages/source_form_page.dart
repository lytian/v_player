import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/utils/db_helper.dart';

class SourceFormPage extends StatefulWidget {
  const SourceFormPage({Key? key,
    this.source
  }) : super(key: key);

  final SourceModel? source;

  @override
  State<SourceFormPage> createState() => _SourceFormPageState();
}

class _SourceFormPageState extends State<SourceFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusScopeNode _focusNode = FocusScopeNode();
  final DBHelper _db = DBHelper();

  Map<String, dynamic> _formData = SourceModel().toJson();

  @override
  void initState() {
    super.initState();

    if (widget.source != null) {
      _formData = widget.source!.toJson();
    }
  }

  @override
  void dispose() {
    _db.close();
    _focusNode.dispose();
    BotToast.closeAllLoading();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? '添加视频源' : '修改视频源'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
        child: Form(
          key: _formKey,
          child: FocusScope(
            node: _focusNode,
            child: Column(
              children: [
                _buildFormItem(
                  key: 'name',
                  label: '资源名称',
                  maxLength: 10,
                ),
                _buildFormItem(
                  key: 'type',
                  label: '资源类型',
                  maxLength: 10,
                ),
                _buildFormItem(
                  key: 'url',
                  label: '资源url',
                  hint: '资源首页的url地址',
                  keyboardType: TextInputType.url,
                ),
                _buildFormItem(
                  key: 'httpApi',
                  label: '资源Api',
                  hint: '获取资源的Api地址',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                Container(
                  height: 44,
                  margin: const EdgeInsets.only(top: 80),
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(2),
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                      minimumSize: MaterialStateProperty.all(const Size.fromHeight(44))
                    ),
                    icon: const Icon(Icons.save, color: Colors.white,),
                    label: const Text('提交', style: TextStyle(fontSize: 18, color: Colors.white, height: 1),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormItem({
    required String label,
    required String key,
    String? hint,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLength = 30,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          counterText: '',
          hintText: hint ?? '请输入$label',
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor
          )
        ),
        maxLength: maxLength,
        controller: controller,
        initialValue: controller == null ? _formData[key]?.toString() : null,
        onEditingComplete: _nextFocus,
        onChanged: (val) {
          _formData[key] = val.trim();
        },
        validator: (val) {
          return val == null || val.trim().isEmpty ? (hint == null ? hint : '输入$label') : null;
        },
      )
    );
  }

  void _nextFocus() {
    if (_focusNode.focusedChild != _focusNode.children.last) {
      _focusNode.nextFocus();
    }
  }

  void _submit() {
    final _form = _formKey.currentState;
    if (_form!.validate()) {
      _form.save();
      final CancelFunc cancelFunc = BotToast.showLoading();
      try {
        if (_formData['id'] == null) {
          // 新增
          _db.insertSource(SourceModel.fromJson(_formData));
          BotToast.showText(text: '添加成功！');
        } else {
          // 编辑
          _db.updateSourceById(SourceModel.fromJson(_formData));
          BotToast.showText(text: '修改成功！');
        }
      } finally {
        cancelFunc.call();
        Navigator.of(context).pop();
      }
    }
  }
}
