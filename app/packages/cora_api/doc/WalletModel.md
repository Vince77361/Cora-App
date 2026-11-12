# cora_api.model.WalletModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**account** | [**WalletAccountModel**](WalletAccountModel.md) | 등록 전이면 null. | 
**entries** | [**List<WalletEntryModel>**](WalletEntryModel.md) | 기준 시각 최신순. 식사권 줄은 같은 협업의 돈 줄 바로 아래. | [default to const []]
**heldAmount** | **int** | 지금 Cora가 보관 중인 내 협업들의 금액 합(원). | 
**nextPayout** | [**WalletNextPayoutModel**](WalletNextPayoutModel.md) | 지급 예정이 없으면 null. | 
**receivedThisMonth** | **int** | 이번 달(한국 시간) 송금이 끝난 지급의 합(원). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


