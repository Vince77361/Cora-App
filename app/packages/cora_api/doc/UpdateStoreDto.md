# cora_api.model.UpdateStoreDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**bestShootingTime** | **String** |  | [optional] 
**category** | **String** | 표시용 업종(예: 라멘집). | [optional] 
**coverPhotoPath** | **String** |  | [optional] 
**customerPhrases** | **List<String>** | 손님들이 자주 한 말. 최대 3개, 각 20자. | [optional] [default to const []]
**hours** | **String** |  | [optional] 
**industry** | [**IndustryCategory**](IndustryCategory.md) | 업종 분류(공통 모델 3장). | [optional] 
**intro** | **String** |  | [optional] 
**name** | **String** |  | [optional] 
**neighborhood** | **String** | 표시용 동네(예: 성수동). | [optional] 
**recruitLine** | **String** | 크리에이터에게 보이는 모집 한 줄. 빈 문자열이면 지운다. | [optional] 
**regionSido** | **String** | 시·도 고정 목록(SIDO_LIST) 중 하나. | [optional] 
**regionSigungu** | **String** |  | [optional] 
**seats** | **String** |  | [optional] 
**signatureMenu** | **String** |  | [optional] 
**tags** | **List<String>** | 꼬리표(# 없이). 최대 5개, 각 10자. | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


