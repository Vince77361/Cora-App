# cora_api.model.StoreResultModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**creator** | [**StoreResultCreatorModel**](StoreResultCreatorModel.md) |  | 
**fixedCash** | **int** | 고정 현금(원). 없으면 0. | 
**fixedCashOnly** | **bool** | 고정 현금만 있던 협업이면 true. 조회수를 세지 않아 조회수와 비교 상자가 없다. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**multiplierTenths** | **int** | 평소 대비 배수를 10배 한 정수(31 = 3.1배, 소수 첫째 자리까지 내림). 평소 조회수가 없으면 null. | 
**payout** | **int** | 크리에이터 지급액(원). | 
**postUrl** | **String** | 크리에이터가 낸 게시 링크. | 
**postedAt** | [**DateTime**](DateTime.md) | 크리에이터가 게시 링크를 낸 시각(ISO 8601). | 
**refund** | **int** | 사장님께 환불한 금액(원). | 
**usualViews** | **int** | 가게 인스타그램 계정의 평소 조회수. 링크가 없거나 읽지 못했으면 null이고, 그러면 비교 상자를 숨긴다. | 
**views** | **int** | 정산에 쓴 최종 조회수. 조회수를 세지 않은 협업은 null. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


