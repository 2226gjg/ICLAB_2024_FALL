import random

def hamming_encode(data: str) -> str:
    if len(data) != 11 or not all(bit in '01' for bit in data):
        raise ValueError("Input must be an 11-bit binary string.")

    # 將數據位和檢查位初始化
    # 檢查位的位置是 1, 2, 4, 8，數據位放在剩下的位置
    code = ['0'] * 15  # 15 位元，初始化為 0

    # 將數據位放入對應的位置
    code[2] = data[0]   # d1
    code[4] = data[1]   # d2
    code[5] = data[2]   # d3
    code[6] = data[3]   # d4
    code[8] = data[4]   # d5
    code[9] = data[5]   # d6
    code[10] = data[6]  # d7
    code[11] = data[7]  # d8
    code[12] = data[8]  # d9
    code[13] = data[9]  # d10
    code[14] = data[10] # d11

    # 計算檢查位
    # 檢查位 1 (p1)
    code[0] = str(int(code[2]) ^ int(code[4]) ^ int(code[6]) ^ int(code[8]) ^ int(code[10]) ^ int(code[12])^int(code[14]))

    # 檢查位 2 (p2)
    code[1] = str(int(code[2]) ^ int(code[5]) ^ int(code[6]) ^ int(code[9]) ^ int(code[10]) ^ int(code[13])^int(code[14]))

    # 檢查位 4 (p4)
    code[3] = str(int(code[4]) ^ int(code[5]) ^ int(code[6]) ^ int(code[11]) ^ int(code[12]) ^ int(code[13])^int(code[14]))

    # 檢查位 8 (p8)
    code[7] = str(int(code[8]) ^ int(code[9]) ^ int(code[10]) ^ int(code[11]) ^ int(code[12]) ^ int(code[13])^int(code[14]))


    # 將列表轉換為字串
    encoded_number = ''.join(code)

    # 隨機決定是否翻轉一個位元
    if random.choice([True, False]):  # 50% 機率翻轉一位
        random_index = random.randint(0, len(encoded_number) - 1)  # 隨機選擇位元位置
        flipped_bit = '1' if encoded_number[random_index] == '0' else '0'
        encoded_number = encoded_number[:random_index] + flipped_bit + encoded_number[random_index + 1:]

    return encoded_number
    
def generate_random_11bit_numbers(count: int) -> list:
    return [''.join(random.choices('01', k=11)) for _ in range(count)]

def main():
    # 生成 100 筆 11 位數字
    random_numbers = generate_random_11bit_numbers(100)

    # 編碼並輸出到 input_11.txt
    with open('input_11.txt', 'w') as output_file:
        for number in random_numbers:
            encoded_number = hamming_encode(number)
            output_file.write(f"{encoded_number}\n")

    # 將原始數據輸出到 output_11.txt
    with open('output_11.txt', 'w') as input_file:
        for number in random_numbers:
            input_file.write(f"{number}\n")

    print("已將編碼和原始數據分別輸出至 input_11.txt 和 output_11.txt")

if __name__ == "__main__":
    main()
