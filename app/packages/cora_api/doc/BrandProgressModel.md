# cora_api.model.BrandProgressModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**current** | **int** | 지금 하는 단계(1~6). 모두 끝났으면 null. | 
**currentNote** | [**BrandProgressNote**](BrandProgressNote.md) | 현재 단계 줄의 보조 글. WAITING_OTHER_CONFIRM: 상대의 동의를 기다림, WAITING_CONTRACT: 계약을 진행해야 함. | 
**doneCount** | **int** | 끝난 단계의 수(0~6). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


