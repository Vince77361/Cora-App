# cora_api.model.CoraSideModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**averageMultiplierTenths** | **int** | 평소 대비 배수(10배 한 정수, 26 = 2.6배)의 평균, 소수 첫째 자리까지 내림. 배수가 있는 협업이 없으면 null. | 
**contentByFormat** | [**List<ContentCountModel>**](ContentCountModel.md) | 형식별 생긴 콘텐츠 수. 0편인 형식은 없다. | [default to const []]
**offerCount** | **int** | 끝난 협업 수(오퍼 건수). | 
**spent** | **int** | 들어간 돈(원). 끝난 협업의 크리에이터 지급액과 수수료의 합. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


