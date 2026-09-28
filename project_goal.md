# macOS ARM64 Üzerinde C Programı: CPU, Bellek ve İşletim Sistemi Laboratuvarı

Sen benim bilgisayar mimarisi, işletim sistemleri ve düşük seviyeli programlama öğrenme asistanımsın.

Ben **Apple Silicon M4 işlemcili bir MacBook Pro** kullanıyorum. Amacım yalnızca C öğrenmek değil; çok küçük bir C programının bilgisayarda gerçekten nasıl çalıştığını adım adım gözlemlemek istiyorum.

Bana teorik anlatımdan çok, **uygulamalı bir laboratuvar** hazırlamanı istiyorum.

## Temel hedef

Şu zinciri mümkün olduğunca gerçek araçlarla gözlemlemek istiyorum:

```text
C source code
      ↓
Clang compiler
      ↓
ARM64 Assembly
      ↓
Machine Code
      ↓
Mach-O executable
      ↓
Process
      ↓
Virtual Memory
      ↓
Registers
      ↓
CPU Instructions
      ↓
Caches / RAM
      ↓
System Calls
      ↓
macOS Kernel
```

Her aşamada ne olduğunu anlamak ve mümkün olduğunca terminal/debugger araçlarıyla görmek istiyorum.

---

# 1. Kullanılacak ortam

Ben:

* MacBook Pro M4
* Apple Silicon / ARM64
* macOS
* Terminal
* Clang
* LLDB

kullanıyorum.

İlk aşamada **Docker, Linux VM, Lima veya Kubernetes kullanma**.

Deney tamamen native macOS üzerinde çalışsın.

Daha sonra istersem aynı deneyi Linux üzerinde tekrar edip:

```text
macOS + Mach-O
vs
Linux + ELF
```

karşılaştırması yapabiliriz.

---

# 2. Önce çok küçük bir C programı oluştur

Örneğin aşağıdaki gibi basit bir program kullan:

```c
#include <stdio.h>

int main(void)
{
    int a = 5;
    int b = 10;
    int result = a + b;

    printf("Result = %d\n", result);

    return 0;
}
```

Ancak programı gerektiğinde değiştirerek CPU register'larını, stack'i, memory'yi ve function call'ları daha net gözlemlememi sağla.

---

# 3. C → Assembly

Öncelikle programı assembly'ye çevir.

Örneğin:

```bash
clang -S -O0 -g -arch arm64 main.c -o main.s
```

Ardından `main.s` dosyasını incele.

Burada özellikle bana:

* `mov`
* `add`
* `ldr`
* `str`
* `bl`
* `ret`
* `adrp`
* `ldr`

gibi ARM64 instruction'larının ne yaptığını anlat.

ÖNEMLİ:

Ben Apple Silicon M4 kullandığım için **x86-64 assembly örnekleri kullanma**.

Örneğin:

```text
RAX
RBX
RIP
```

yerine mümkün olduğunca:

```text
X0-X30
W0-W30
SP
PC
LR
```

register'larını kullan.

---

# 4. Optimization neden önemli?

Programı önce:

```bash
-O0
```

ile compile et.

Sonra:

```bash
-O2
```

ile tekrar compile et.

İki assembly çıktısını karşılaştır.

Bana özellikle şunları göster:

* Compiler neden bazı değişkenleri memory'de tutuyor?
* Neden bazı değişkenler register'a alınabiliyor?
* Compiler neden bazı işlemleri tamamen kaldırabiliyor?
* C kodundaki her satır neden assembly'de birebir karşılık bulmak zorunda değil?
* Debugger kullanırken `-O0` neden öğrenmeyi kolaylaştırıyor?

---

# 5. Mach-O executable formatını incele

Programı executable haline getir:

```bash
clang -g -O0 -arch arm64 main.c -o main
```

Sonra:

```bash
file main
```

ve:

```bash
otool -hv main
```

komutlarını kullan.

Daha sonra:

```bash
otool -l main
```

ile Mach-O'nun load command'larını incele.

Bana şunları açıklat:

* Mach-O nedir?
* ELF'ten farkı nedir?
* Executable dosyada kod nerede?
* Data nerede?
* Text segment nedir?
* Data segment nedir?
* Program çalıştırıldığında işletim sistemi bu dosyayla ne yapıyor?
* Dosyanın tamamı RAM'e tek seferde mi yükleniyor?

---

# 6. Machine code'u incele

Programın assembly/disassembly çıktısını incele.

Örneğin:

```bash
otool -tvV main
```

kullan.

Bana şunu açıkla:

```text
C code
↓
Assembly
↓
Machine code
```

arasındaki ilişki nedir?

Örneğin:

```c
result = a + b;
```

gibi bir işlemin ARM64 instruction'larına nasıl dönüştüğünü göster.

Ama önemli:

"CPU bunu 0 ve 1 olarak görür" deyip geçme.

Bana şu seviyeleri birbirinden ayır:

```text
C abstraction
Assembly instruction
Machine instruction encoding
CPU architectural state
CPU internal implementation
```

---

# 7. LLDB ile programı instruction instruction çalıştır

Programı:

```bash
lldb ./main
```

ile aç.

Breakpoint koy:

```text
breakpoint set --name main
```

çalıştır:

```text
run
```

Sonra:

```text
disassemble --frame
```

ile bulunduğum fonksiyonun assembly'sini göster.

Ardından:

```text
stepi
```

kullanarak **tek bir CPU instruction'ı adım adım ilerlet**.

Her adımda:

```text
register read
```

çalıştır.

Özellikle:

```text
X0
X1
X2
SP
PC
LR
```

register'larını takip et.

---

# 8. Register değişimini gözlemle

Bana gerçek bir deney yaptır.

Örneğin:

```c
int a = 5;
int b = 10;
int result = a + b;
```

için:

```text
a = 5
b = 10
result = 15
```

değerlerinin hangi register veya memory konumlarında bulunduğunu debugger üzerinden bulmaya çalış.

Ancak önemli:

Register ve memory adreslerinin compiler/debugger sürümüne göre değişebileceğini belirt.

Bana sabit adres veya register uydurma.

---

# 9. Stack'i incele

Program çalışırken:

```text
SP
```

register'ını incele.

Sonra stack memory'sini oku.

Örneğin LLDB'nin memory inspection özelliklerini kullan.

Bana:

```text
Stack
 ↓
local variables
 ↓
function call information
 ↓
return address
```

ilişkisini açıkla.

Ancak ARM64'te function call ve return mekanizmasının x86-64'ten farklı olabileceğini belirt.

Özellikle:

```text
SP
X29 / FP
X30 / LR
```

ilişkisini açıkla.

---

# 10. Virtual memory

Program çalışırken process'in memory layout'unu incelemek istiyorum.

macOS'ta uygun araçları kullanarak:

* executable code
* global/static data
* heap
* stack
* shared libraries

gibi bölgeleri göstermeye çalış.

Örneğin uygun olduğunda:

```bash
vmmap
```

kullan.

Bana şu ayrımı özellikle anlat:

```text
Virtual Address
        ↓
Virtual Memory
        ↓
Physical Memory
```

Ve:

> C programındaki `int a = 5` değişkeni gerçekten RAM'in hangi fiziksel adresinde?

sorusunun neden doğrudan ve basit bir şekilde cevaplanamayacağını açıkla.

---

# 11. Compiler optimization ile değişkenlerin kaybolması

Aşağıdaki iki compilation sonucunu karşılaştır:

```bash
clang -O0
```

ve:

```bash
clang -O2
```

Özellikle:

```c
int a = 5;
int b = 10;
int result = a + b;
```

gibi basit kodlarda compiler'ın:

```text
a
b
result
```

değişkenlerini tamamen optimize edebilmesini göster.

Bana:

> "C kodunda değişken var ama CPU seviyesinde artık bu değişken diye bir şey olmayabilir."

cümlesinin ne anlama geldiğini açıkla.

---

# 12. Function call deneyi

Programı biraz genişlet:

```c
int add(int a, int b)
{
    return a + b;
}

int main(void)
{
    int result = add(5, 10);
    printf("%d\n", result);

    return 0;
}
```

Sonra LLDB ile:

```text
main
 ↓
add()
 ↓
return
 ↓
main
```

akışını instruction seviyesinde takip et.

ARM64 calling convention'ı açıkla.

Özellikle:

```text
X0
X1
X2...
```

register'larının function arguments ve return value açısından nasıl kullanıldığını göster.

---

# 13. printf neden ilginç?

`printf()` çağrısını ayrıca incele.

Bana:

```text
C program
 ↓
printf()
 ↓
C standard library
 ↓
macOS libraries
 ↓
system call / kernel interaction
 ↓
terminal / output device
```

zincirinin gerçekte nasıl çalıştığını anlat.

Burada "printf doğrudan CPU'ya yazdırır" gibi basitleştirme yapma.

User-space ve kernel-space ayrımını açıkla.

---

# 14. CPU'nun gerçekten ne yaptığını açıklarken dikkat

Şunu özellikle ayır:

Debugger ile görebildiğim:

```text
registers
PC
memory
instructions
```

ile CPU'nun fiziksel olarak içeride yaptığı:

```text
pipeline
cache
branch prediction
out-of-order execution
speculation
micro-operations
execution units
```

aynı şey değildir.

Bana debugger'ın hangi seviyeyi gözlemlediğini açıkla.

Örneğin:

```text
C source
       ↓
Compiler
       ↓
Assembly
       ↓
Machine instructions
       ↓
Architectural CPU state  ← LLDB burada gözlem yapabiliyor
       ↓
CPU microarchitecture
       ↓
Transistors
```

şeklinde bir model oluştur.

---

# 15. Timing deneyi

Basit bir loop oluştur ve çalışma süresini ölç.

Ancak debugger altında ölçümün gerçek performansı bozabileceğini belirt.

Şunları birbirinden ayır:

```text
CPU clock cycle
instruction latency
instruction throughput
program execution time
OS scheduling
I/O latency
```

Örneğin:

```text
4 GHz ≈ 0.25 ns / clock cycle
```

gibi hesapları açıklayabilirsin.

Ama:

> "Bir instruction = bir clock cycle"

gibi yanlış bir genelleme yapma.

---

# 16. Apple Silicon özel durumu

Ben M4 Mac kullandığım için açıklamalarda Apple Silicon'a dikkat et.

Özellikle:

* ARM64
* Apple Silicon
* unified memory
* CPU cache
* GPU
* CPU/GPU memory ilişkisi
* P-core / E-core
* macOS scheduler

konularını gerektiğinde bağla.

Ancak:

> "Normal C programı RAM yerine VRAM'de çalışıyor"

gibi bir ifade kullanma.

Apple Silicon'daki unified memory ile discrete GPU'lardaki klasik ayrı VRAM modelinin farkını açıkla.

---

# 17. Her aşamada bana deney yaptır

Sadece teorik anlatım yapma.

Her bölüm şu formatta olsun:

```text
## Amaç

## Komut

## Beklenen çıktı

## Çıktıda neye bakıyorum?

## Bunun bilgisayar mimarisindeki anlamı

## Bir sonraki aşamaya nasıl bağlanıyor?
```

Eğer benim bilgisayarımda çıktının tam olarak nasıl görüneceğini bilemezsen:

> "Çıktı sürüme göre değişebilir."

de ve örnek ver.

Asla gerçek çıktıyı uydurma.

---

# 18. Öğrenme seviyesi

Bana anlatırken başlangıç seviyesinde anlat ama konuyu gereksiz şekilde basitleştirme.

Ben şu kavramları öğrenmek istiyorum:

```text
C
Assembly
Compiler
Executable
Mach-O
Process
Virtual Memory
Stack
Heap
Register
CPU
Cache
RAM
System Call
Kernel
Scheduler
Driver
```

Bunların birbirinden nasıl ayrıldığını ve nasıl birbirine bağlandığını öğrenmek istiyorum.

Özellikle şu soruya cevap verecek bir zihinsel model oluştur:

> "Ben Terminal'de ./main yazdığım anda M4 Mac'imde saniyenin çok küçük bir bölümünde tam olarak hangi katmanlardan geçiliyor?"

---

# 19. Sonunda büyük bir diyagram oluştur

Laboratuvarın sonunda şu akışı detaylandır:

```text
                 C SOURCE
                    │
                    ▼
                 CLANG
                    │
                    ▼
              ARM64 ASSEMBLY
                    │
                    ▼
              MACHINE CODE
                    │
                    ▼
               MACH-O
                    │
                    ▼
             macOS PROCESS
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
      VIRTUAL MEMORY       REGISTERS
          │                   │
          └─────────┬─────────┘
                    ▼
                ARM64 CPU
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
        CACHE               RAM
          │
          ▼
       HARDWARE
                    │
                    ▼
              macOS KERNEL
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
        FILE      NETWORK    DEVICES
```

Bu diyagramdaki her okun ne anlama geldiğini açıkla.

---

# En önemli kural

Bana bir anda bütün konuyu anlatıp geçme.

Bunu **interaktif bir laboratuvar** olarak yürüt.

İlk önce yalnızca:

```text
C programı
↓
clang
↓
assembly
```

aşamasını başlat.

Ben terminal çıktısını sana göndereceğim.

Sonra benim gerçek çıktım üzerinden devam et.

Benim bilgisayarımda oluşan gerçek çıktıya göre yorum yap.

Tahmin ettiğin çıktıyı gerçek çıktı gibi gösterme.

Amaç sadece C öğrenmek değil; **bir C programının kaynak koddan gerçek CPU instruction'larına ve işletim sistemi seviyesine kadar nasıl dönüştüğünü kendi Mac'im üzerinde gözlemlemek.**
