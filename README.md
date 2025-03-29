# 🗣️ 레츠톡 (Ret's talk)

<img src="https://github.com/user-attachments/assets/d73258bb-93f4-4dd7-8051-958d49816c77"/>

> 번거로운 회고, 저희가 도와줄게요. </br>
> 대화 형식으로 회고하는 회고 서비스 앱 "**레츠톡**"

<img src="https://github.com/user-attachments/assets/e974f1d1-db4a-4f02-91a3-e6ca8f417ea4"/>

## 🖐️ 간단 소개

- 💬 AI 챗봇의 도움으로 회고를 대화하듯이 할 수 있어요.
- 🤓 회고의 요약을 볼 수 있어요.
- 🤔 회고를 리마인드 할 수 있도록 북마크 기능을 제공해요.
- 📳 회고를 잊지 않도록 알림을 보내드려요.

## 🧑🏻‍💻 개발자들

<table>
<tr>
    <td align="center"><img src="https://github.com/gen-com.png" width="160"></td>
    <td align="center"><img src="https://github.com/alstjr7437.png" width="160"></td>
    <td align="center"><img src="https://github.com/MoonGoon72.png" width="160"></td>
    <td align="center"><img src="https://github.com/1win2.png" width="160"></td>
</tr>
<tr>
    <td align="center">S006_구병조</td>
    <td align="center">S013_김민석</td>
    <td align="center">S021_문영균</td>
    <td align="center">S066_조한승</td>
</tr>
<tr>
    <td align="center"><a href="https://github.com/gen-com" target="_blank">@gen-com</a></td>
    <td align="center"><a href="https://github.com/alstjr7437" target="_blank">@alstjr7437</a></td>
    <td align="center"><a href="https://github.com/MoonGoon72" target="_blank">@MoonGoon72</a></td>
    <td align="center"><a href="https://github.com/1win2" target="_blank">@1win2</a></td>
</tr>
</table>

## 💾 핵심 경험

### 💫 회고의 동시성 문제

<details>
<summary>자세히 보기</summary>
</br>

애플리케이션의 핵심 데이터는 📒**회고**입니다.

<img src="https://github.com/user-attachments/assets/66e871ce-82ee-4a9f-9720-084aad5b7e94" width="400">

회고를 관리하는 과정에서 사용자에 요구에 의해 네트워크와 로컬 저장소의 비동기 작업이 필요하며, 또 화면에 보여줄 수 있어야 합니다.

즉, 회고는 🟠**여러 스레드에서 접근할 수 있는 가변 공유 데이터**가 됩니다.

사용자가 신뢰할 수 있도록 데이터를 동시성의 상황에서 안전하게 관리해야 합니다.

동시성 코드는 올바르게 작성하기 힘들고, 유지 그리고 확장까지 하는 것은 더 큰 어려움입니다.

주요한 이유에서는
- 🔴**실행시간이 되어서야 뭔가 잘못되었다는 것을 알 수 있기 때문**입니다.
- 때로는 잘못 작성했는데, 🔴**실행 시간에 발견되지 않을 수도 있습니다.**

</details>

### 💫 동시성 문제 해결 방안 분석

<details>
<summary>자세히 보기</summary>
</br>

2021년 Swift Concurrency를 발표했고, 2024년 Swift 6가 나오며 동시성을 더 강화해 컴파일 시간에 데이터 경쟁을 감지할 수 있도록 했습니다.

이게 왜 가능할까요 ? 🟢**어떻게 실행시간에 알 수 있던 것을 정적인 컴파일 시간으로 가져올 수 있었을까요 ?**

이 부분에 대해 나름대로 해석을 해봤습니다. 잘못된 내용이 있을 수 있으며, 지적은 언제나 환영입니다.

이제부터 우리는 컴파일러가 되어 다음의 코드를 분석해 봅시다.

```swift
class BoostCamp {
    private(set) var campers: [Person]
    private let queue: DispatchQueue
    
    init() {
        campers = []
        queue = DispatchQueue(label: "com.naver.boostcamp.serialQueue")
    }
    
    func enroll(person: Person) {
        campers.append(person)
    }
}

// MARK: Conconrrency code

var naverBoostCamp = BoostCamp()

DispatchQueue.global().async {
    naverBoostCamp.enroll(Person("JK"))
}

DispatchQueue.global().async {
    naverBoostCamp.enroll(Person("BK"))
}
```

우리는 이 코드가 데이터 경쟁 문제를 야기할 수 있다는 것을 알 수 있지만, 컴파일러는 소스 코드를 바탕으로 어휘 구문 의미를 분석할 뿐, 실행 시간 데이터를 알 수 없습니다.

🔴만일 더 복잡한 사항이고, 우리도 데이터 경쟁이 발생할 수 있다는 상황을 인지하지 못했다면 아마 끔찍한 상황으로 이어질 것입니다.

그러면 컴파일러가 동시성 문제를 알 수 있도록 하기 위해서 필요한 것은 무엇일까요 ?

🟢관련한 정보를 더 제공하면 되지 않을까요 ?
- ✅ 이 데이터는 동시성의 상황에서 안전하게 처리된다.
- 🛑 저 데이터는 동시성의 상황에서 안전하지 않아서 주의해야 한다.

</details>

### 💫 데이터 격리 개념 정리

<details>
<summary>자세히 보기</summary>
</br>

`actor`는 🔵**타입을 확장**하고, 🔵**데이터 격리의 개념**을 얻습니다. 크게 두 영역으로 나눌 수 있는데,

- 비격리 영역(non-isolated domain)
- 격리 영역(actor-isolated domain)

이제 컴파일러는 🚨`비격리 영역 - 다중 접근 가능`, 🏝️`격리 영역 - 단일 접근만 허용`이라는 개념을 장착하고 동시성 문제를 파악할 수 있게 됩니다.

- 🚨비격리 → 🚨비격리: 다중 접근이 허용되는 곳끼리 문제는 없음.
- 🏝️격리 → 🚨비격리: 다중 접근이 허용되는 곳으로 가는 것은 문제 없음.
- 🏝️격리 → 같은 격리: 같은 격리 도메인에서 작업 수행은 문제 없음.

다음은 주의가 필요합니다.

- 🚨비격리 → 🏝️격리: 격리는 단일 접근만 허용하므로 차례를 기다려야함.
- 🏝️격리 → 🏝️다른 격리: 각 격리끼리도 단일 접근만 허용하므로 차례를 기다려야함.

격리간 소통하는 것은 위와 같이하면 됩니다.

---

격리가 다른 경우에 데이터를 전달해야 한다면 어떨까요 ?

그 데이터가 어떤 형식인가가 중요합니다. 데이터 경쟁에 위험이 있는 데이터라면 주고 받는 행위를 허용하지 않아야 합니다.

여기서 또 하나의 타입 개념을 도입합니다. 바로 `Sendable` !

보낼 수 있는 데이터, 더 자세하게는 🔵**안전하게 보낼 수 있는 데이터**를 의미합니다.

데이터 경쟁은 🔴**공유**되는 🔴**가변**데이터에 🔴**둘 이상의 접근에 하나 이상이 쓰기 작업**을 할 때 발생합니다.

그렇다면 데이터가 `Sendable`하기 위한 조건은 다음과 같습니다.

- 🟢 공유를 허용하지 않거나 → 순수 값타입(복사를 통한 전달)
- 🟢 값이 변하지 않거나 → 불변한 상수 값
- 🟢 상호 베타적 접근만 허용하거나 → 액터와 같은 타입

---

이제 다시 아래의 코드를 분석해 봅시다.

```swift
class BoostCamp {
    private(set) var campers: [Person]
    
    init() {
        campers = []
    }
    
    func enroll(person: Person) {
        campers.append(person)
    }
}

// MARK: Conconrrency code

var naverBoostCamp = BoostCamp()

Task {
    naverBoostCamp.enroll(Person("JK"))
}

Task {
    naverBoostCamp.enroll(Person("BK"))
}
```

BoostCamp라는 타입이 격리되어 있지 않음을 알 수 있습니다.

그리고 Task 동시성 환경에서 값을 변경하려 하는데, 이는 안전하지 않겠구나 판단할 수 있습니다.

</details>

### 💫 데이터 격리 프로젝트에 적용하기

<details>
<summary>자세히 보기</summary>
</br>

데이터 격리의 개념을 잡고 프로젝트에 적용해 봅니다.

동시성의 문제가 발생할 수 있는 곳에 `actor`를 적용하면 다음과 같습니다.

<img src="https://github.com/user-attachments/assets/e1381565-59ce-4668-ae1c-3a19c4de2b4a" width="400">

문제가 될 수 있는 부분을 살펴 봅시다.

회고 관리자와 회고 대화 관리자가 각각 격리가 되어 있습니다. 회고 대화 관리자는 회고 관리자로부터 회고 데이터를 받습니다.

🟠**회고 데이터는 둘 사이에서 계속 동기화가 되어야 하는데, 지금은 둘 사이가 격리되어 있습니다.**

그래서 비동기의 상황에서 차례를 기다려야 합니다. 근데 변화가 여러번 생길 수 있으며 그때마다 비동기 태스크가 발생하면 문제가 됩니다.

<img src="https://github.com/user-attachments/assets/761a7bad-fadd-4662-b2be-e3eeefacd4a7" width="400">

상호 베타적인 접근만 허용해서 저수준의 데이터 경쟁은 없는 것이 보장이 되지만, 🔴**여러개의 비동기 태스크가 어떤 순서로 수행되는지는 보장되지 않습니다.**

그렇게 고수준의 데이터 경쟁이 발생할 수 있습니다.

사실 이 둘 사이는 격리되어있을 이유가 없습니다. 둘은 의존관계에 있고, 상태 관리가 동기적으로 이뤄지는 것이 더욱 안전한 구조이기 때문입니다.

격리를 하는 것은 좋지만, 🟠**격리간의 데이터 송수신이 비동기가 되면서 문제가 될 수 있는 경우는 격리를 나누는 것이 좋은 선택은 아닙니다.**

정리를 하면,

<img src="https://github.com/user-attachments/assets/fed3e1a9-b8f0-4f50-b081-ac03abc2aa17" width="400">

격리는 총 세 영역으로, **메인 액터**와 **저장소 액터** 그리고 **비격리**로 나뉩니다.

- **메인 액터**
    - 화면적 요소와 아주 가벼운 작업을 처리합니다.
    - 회고도 메인 액터에 포함됩니다.
        - 네트워크나 저장소 작업으로 가져온 회고에 대해 무거운 작업을 수행하지 않습니다.
        - 그리고 고수준의 데이터 경쟁 없이 화면에 렌더링하기 위해서 같은 격리에 있는 것이 좋습니다.

- **저장소 액터**
    - 저장소 액터는 DB의 무거운 작업을 처리하고 회고 데이터를 안전하게 보호합니다.

- **네트워크 비격리**
    - 네트워크 작업은 따로 격리를 가지지 않습니다.
    - 격리가 되면 해당 영역에서 작업을 수행할 때, 한 번에 하나씩만 수행합니다.
    - 네트워크 작업은 서로 독립적이기에, **격리로 나누는 것은 불필요한 병목 현상을 만들어냅니다.**

</details>

## 🔥 추가 학습

### ✨ 반응형의 의미

<details>
<summary>자세히 보기</summary>
</br>

[반응형에 대한 설명 영상](https://www.youtube.com/watch?v=sTSQlYX5DU0)을 보고 해석한 내용으로 오류가 있을 수 있습니다.

반응형(Reactive)의 의미는 무엇인가요 ?

> 💡**반응형은 부작용(Side effect)을 처리하는 인터페이스입니다.**

---

객체를 아주 단순하게 생각하면, `Getter`와 `Setter`들로 볼 수 있습니다.

```swift
class Person {
	...
	
	var age: Int {
		get { ... }
		set { ... }
	}
	
	...
}
```

#### Getter

`getter`는 값을 반환하는 메소드입니다. 아무것도 인자로 주지 않아도 되고, 그저 값을 반환합니다.

호출 전까지 아무것도 안하며, 🟢**소비자(consumer)가 원할 때 호출**됩니다. 받는 것만 수행하며, 🟢**Pull**의 개념으로 볼 수 있습니다.

발생할 수 있는 예외 상황은 값이 없거나(`optional`), 정상 흐름이 아닌 경우(`error`)가 있습니다.

```swift
class Person {
	...
	
	var age: Int? {
		get throws { ... }
	}
	
	...
}
```

🟢**컬렉션 타입을 열거하는 것도 `getter`로 볼 수 있습니다.**

```swift
protocol Sequence {
	associatedtype Iterator: IteratorProtocol
	
	func makeIterator() -> Iterator
}

protocol IteratorProtocol {
	associatedtype Element
	
	func next() -> Element?
}
```

`IteratorProtocol`의 `next()`가 `getter`이고, `Sequence`의 `makeIterator`가 이를 한 번 더 감싼 `getter의 getter`로 볼 수 있습니다.

#### 💥 No Silver Bullet

`getter`는 공변성을 가지며, Functor입니다.

Functor가 된다는 것은 변환 함수를 적용할 수 있는 연산자(주로 `map`)를 제공하며 다음과 같은 이점을 얻습니다.

- 🟢**선언적 데이터 변환**
    
    `map` 연산자를 사용하면, 각 이벤트(값)를 선언적으로 변환할 수 있습니다.
    
- 🟢**예측 가능성과 안정성**
    
    Functor 법칙을 준수하면 **변환 결과가 수학적으로 보장**되므로, **디버깅과 유지보수가 용이**합니다.
    
    **항등 법칙**은 변환 함수가 없을 때 **원래의 스트림을 그대로 유지함을 보장**하고, **합성 법칙**은 **함수의 합성이 올바르게 작동함을 확인**해 줍니다.
    
- 🟢**함수형 프로그래밍과의 통합**
    
    다른 함수형 추상화(Monad 등)와 자연스럽게 조합할 수 있습니다.
    
    이는 비동기 데이터 처리 및 이벤트 스트림 조합에 있어 매우 강력한 도구가 됩니다.

> 🟢**이렇듯 `getter`는 꽤 매력적인 구조를 가집니다.**

<details>
<summary>🔸공변성(Covariant)과 반공변성(Contravariant)</summary>
</br>

`A`와 `B`를 타입, `f`를 형 변환, 그리고 `<=`을 서브타입 관계성이라 가정하자.

(즉, `A<=B`는 `A`가 `B`의 서브타입을 의미한다)

- `A<=B`일 때 `f(A) <= f(B)`면(서브타입 관계가 유지되면) **Covariant**
- `A<=B`일 때 `f(B) <= f(A)`면(서브타입 관계가 역전되면) **Contravariant**

</details>

<details>
<summary>🔸Functor와 coFunctor</summary>
</br>

- Functor는 `map`연산을 지원하는 컨테이너입니다.
    
    ```swift
    protocol Functor {
    	associatedtype T
    		
    	func map<U>(_ transform: (T) -> U) -> Functor<T>
    }
    ```
    
    간단히, 🟢**값을 변환(map)하는 컨테이너입니다.**
    
    **공변적 특성**을 가지며, **항등 법칙**과 **합성 법칙**을 준수합니다.
    
    ```swift
    container.map { $0 } == container
    container.map(f).map(g) == container.map { g(f($0)) }
    ```
    

- CoFunctor는 `contramap`을 지원하는 컨테이너입니다.
    
    ```swift
    protocol CoFunctor {
    	associatedtype T
        
    	func contramap<U>(_ transform: (U) -> T) -> CoFunctor<U>
    }
    ```
    
    간단히, 🟢**입력의 변환을 적용하는 것**입니다.

</details>

#### Setter

`setter`는 앞선 `getter`와 반대의 개념입니다. 인자로 쓰고자 하는 값을 넘겨주지만, 아무것도 받을 수 없습니다. 또, `getter`와 달리 반공변성이며, coFunctor입니다.

`setter`는 객체의 상태나 값을 변경하는 메소드로, 이러한 🟠**값의 변경은 프로그램의 전체 상태에 영향을 미치는 부작용으로 간주될 수 있습니다.**

> 🟢**값의 변화를 `getter`와 같이 사용할 수 있으면 좋을 것 같습니다.**

`setter`는 반공변성, 즉 서브 타입 관계가 역전되는데 그 상태에서 **한 번 더 연산을 수행하면 관계가 유지** 됩니다. 다시말해 `setter의 setter`가 `getter`처럼 공변성을 가집니다.

뜬금없지만 옵저버 패턴을 가져와 보겠습니다.

```swift
// Observable
protocol Publisher {
	associatedtype Ouput
	 
	func receive<S>(subscriber: S)
}

// Observer
protocol Subscriber {
	associatedtype Input

	func receive(_ input: Input)
	func receive(completion: Completion<Failure>)
}
```

데이터의 변화가 생겼을때 관찰되는 곳(`Observable`)에서 관찰자(`Observer`)로 메시지를 전달하는 기법입니다.
관찰자는 메시지를 받기 위해 `Observable`에 `receive`라는 `setter`를 제공하며, `Observable`의 `receive`로 등록(`set`)됩니다.

🟢**바로 `Observable`(혹은 `Publisher`)은 이벤트 흐름을 생성하는 `setter의 setter`입니다.**
추가로 `Observable`(혹은 `Publisher`)은 map 연산을 지원하는 Functor입니다.

> 🚨**공변성 → Functor는 아닙니다. map 연산이 가능해야 합니다.**

🟢**No silver bullet의 설명처럼, 원본값은 그대로 유지한 채로 필요한 함수를 합성해 올바름이 보장되는 변환을 수행할 수 있습니다.**

`setter`의 경우 🟢**생산자(producer)가 흐름을 관리**합니다. 소비자는 생산자가 보내는 것을 받기만 하며, 🟢**Push**의 개념이 됩니다.

🟢**이는 관찰자의 입장에서, 완료 시점을 예측할 수 없는 비동기 이벤트를 처리하기 좋은 구조가 됩니다.**

</details>

### ✨ Combine과 Swift concurrency 불편한 동거

<details>
<summary>자세히 보기</summary>
</br>

`Combine`과 `Swift concurrency`를 활용해서 비동기 작업을 수월하게 처리할 수 있습니다.

- `Combine`
    - 값의 변화에 대해 흐름을 생성하며, 함수의 합성을 통해 여러 이벤트를 🟢**예상 가능한 형태**로 처리할 수 있습니다.
- `Swift concurrency`
    - `async-await` 문법을 통해 🟢**비동기 작업을 순차적으로 구조화된 코드로 작성**할 수 있습니다.
    - 데이터 격리의 개념과 함께 적용하면, 🟢**컴파일 시간에 동시성 문제를 파악**할 수 있습니다.

> 🤔 **이 둘의 장점만 가져올 수 있다면, 값의 변화와 동시성의 부작용 모두 처리할 수 있지 않을까요 ?**
> 

#### 차이점 분석하기

동시성 프로그래밍에서 중요한 것은 스레드를 어떻게 관리하는가 입니다.

`Swift concurrency`는 앞서 살펴본 데이터의 격리를 활용해서 어떻게 스레드를 활용할 지 결정합니다.

그리고 작업의 처리는 🟢**가능한 스레드를 유지**한 채로 continuation이라는 객체를 교환하는 방식입니다.

<img src="https://github.com/user-attachments/assets/31ae50e0-4f11-4dd1-b6de-79cafe338afe">
(출처: WWDC21 - Swift concurrency: Behind the scenes)

병행적 작업에 대해 스레드보다 더 작은 continuation을 교체하는 것은 비용적으로도 이점이 있습니다.

`Combine`은 `Swift concurrency` 이전에 등장한 반응형 프레임워크입니다.

발생한 이벤트를 어디서 처리하는지 결정할 수 있는 API는 다음과 같습니다.

```swift
let ioPerformingPublisher == // Some publisher.
let uiUpdatingSubscriber == // Some subscriber that updates the UI.

ioPerformingPublisher
    .subscribe(on: backgroundQueue) // upstream
    .receive(on: RunLoop.main) // downstream
    .subscribe(uiUpdatingSubscriber)
```

작업을 처리할 스케줄러(`RunLoop`, `GCD`)를 `subscribe(on:)`이나 `receive(on:)`로 지정하고, 그 스케줄러가 스레드 결정합니다.

GCD를 활용하는 경우 관리하는 큐마다 작업을 처리할 큐를 가져오기에, 🟠**새로운 큐는 새로운 스레드를 야기한다**고 볼 수 있습니다.

<img src="https://github.com/user-attachments/assets/4c8331d1-7872-4fa1-9b0b-aa037d09fa7e">
(출처: WWDC21 - Swift concurrency: Behind the scenes)

#### 차이점 해석하기

`Swift concurrency`는 스레드의 수를 줄이는 방향성을 가지고 있고, GCD는 필요에 따라 여러 스레드를 활용합니다.

🟠**이 둘의 방향성은 대치되며, GCD의 환경에서는 동시성 문제를 컴파일 시점에서 파악할 수 없습니다.**

따라서 `Combine`과 `Swift concurrency`를 함께 사용하는 것은 🟠**스레드 관리 측면에서 문제가 발생**할 수 있습니다.

</details>

### ✨ Swift concurrency를 반응형으로 !

<details>
<summary>자세히 보기</summary>
</br>

반응형 프로그래밍에서 주의해야할 점이 있습니다.

반응형은 값의 변화에서 발생하는 부작용을 처리하는 💡**인터페이스**입니다. 🟠**다시말해, 특정 구현체(**`Rx`**,** `Combine`**)만이 반응형이라는 것은 아닙니다.**

따라서 🟢**값의 변화를 함수 합성이 가능한 스트림의 형태로 흘릴 수만 있다면 반응형**이라 할 수 있습니다.

#### Combine API 살펴보기

`Combine` API에는 `AsyncPublisher`가 있으며, 설명은 다음과 같습니다.

> `AsyncPublisher`는 `AsyncSequence`를 준수하며, 이를 통해 호출자는 `Subscriber`를 등록하는 대신 `for-await-in` 구문으로 값을 수신할 수 있습니다.

아주 흥미롭습니다. Publisher 수준에서 `async-await` 구문을 사용할 수 있는 것으로 보입니다. 살짝 더 나아가, `AsyncSequence`를 살펴보면 좋을 것 같습니다.

#### AsyncSequence 분석하기

`AsyncSequence`는 한 번에 하나씩 살펴볼 수 있는 값 목록을 제공한다는 점에서 `Sequence`와 유사합니다.

🟢**차이점은 비동기성이 추가되었다는 것입니다.**

`AsyncSequence`는 처음 사용할 때 값이 모두 있거나, 조금 있거나, 아예 없을 수도 있습니다. 대신 `await`로 다음 값이 오기 까지 기다릴 수 있습니다.
특히 `AsyncSequence`를 구현하는 `AsyncStream`가 매력적인데, 내부에 `continuation` 객체가 있어 `yield`와 `finish` 메소드로 흐름을 제어할 수 있습니다.

아래의 예시를 봅시다.

```swift
extension QuakeMonitor {
    static var quakes: AsyncStream<Quake> {
        AsyncStream { continuation in
            let monitor = QuakeMonitor()
            
            monitor.quakeHandler = { quake in
                continuation.yield(quake)
            }
            
            continuation.onTermination = { @Sendable _ in
                 monitor.stopMonitoring()
            }
            
            monitor.startMonitoring()
        }
    }
}
```

`Quake`에 대한 `AsyncStream`을 생성하는데, `Quake`가 발견되면 `quakeHandler`를 통해 `yield`로 흘려보냅니다.

```swift
for await quake in QuakeMonitor.quakes {
    print("Quake: \(quake.date)")
}
print("Stream finished.")
```

이를 받는 쪽에서는 `await`로 값이 오기를 기다리면 됩니다.

#### AsyncStream 해석하기

`AsyncStream`은 `getter`(`정확히는 getter의 getter`)이며, `yield`로 값을 흘려보낼 수 있습니다.

🟢**즉, `getter`로서 예측 가능한 함수의 합성을 허용하며, 값의 변화를 스트림으로 흘려보낼 수 있습니다.**

반응형의 인터페이스를 만족하므로, 💡**AsyncStream을 통해 Swift concurrency는 반응형의 구현체가 될 수 있다는 해석을 내릴 수 있습니다.**

</details>

## 문서

| [WiKi](https://github.com/boostcampwm-2024/iOS01-boostproject/wiki) | [팀 노션](https://level-mole-239.notion.site/129124f2c5a480348bf1d5f4b1a4b5b7?pvs=4) | [그라운드룰](https://github.com/boostcampwm-2024/iOS01-boostproject/wiki/%EA%B7%B8%EB%9D%BC%EC%9A%B4%EB%93%9C%EB%A3%B0) | [컨벤션](https://github.com/boostcampwm-2024/iOS01-boostproject/wiki/%EC%BB%A8%EB%B2%A4%EC%85%98) | [회의록](https://level-mole-239.notion.site/129124f2c5a481cebb50e2ec49310ba2?pvs=4) | [기획/디자인](https://www.figma.com/design/zMfreNb94N10uKDHizHXF5/Ret's-Talk?node-id=66-1872&t=C78fv57BD0ACgwct-1) |
| :-----------------------------------------------------------------: | :----------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------: |
