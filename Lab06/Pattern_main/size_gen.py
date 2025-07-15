import random
def hamming_encode(data: str) -> str:
    if len(data) != 5 or not all(bit in '01' for bit in data):
        raise ValueError("Input must be a 5-bit binary string.")

    # 將數據位和檢查位初始化
    # 檢查位的位置是 1, 2, 4, 8，數據位放在剩下的位置
    code = ['0'] * 9  # 9 位元，初始化為 0

    # 將數據位放入對應的位置
    code[2] = data[0]  # d1
    code[4] = data[1]  # d2
    code[5] = data[2]  # d3
    code[6] = data[3]  # d4
    code[8] = data[4]  # d5

    # 計算檢查位
    # 檢查位 1 (p1)
    code[0] = str(int(code[2]) ^ int(code[4]) ^ int(code[6]) ^ int(code[8]))
    
    # 檢查位 2 (p2)
    code[1] = str(int(code[2]) ^ int(code[5]) ^ int(code[6]) )

    # 檢查位 4 (p4)
    code[3] = str(int(code[4])^ int(code[5]) ^ int(code[6]))
    # 檢查未 8 (p8)
    code[7]=str(int(code[8]))

     # 將列表轉換為字串
    encoded_number = ''.join(code)

    # 隨機決定是否翻轉一個位元
    if random.choice([True, False]):  # 50% 機率翻轉一位
        random_index = random.randint(0, len(encoded_number) - 1)  # 隨機選擇位元位置
        flipped_bit = '1' if encoded_number[random_index] == '0' else '0'
        encoded_number = encoded_number[:random_index] + flipped_bit + encoded_number[random_index + 1:]

    return encoded_number

def generate_random_5bit_numbers(count: int) -> list:
    choices = ['00100', '00110', '10110']
    return [random.choice(choices) for _ in range(count)]


def main():
    group_count = 500
    with open('input_size.txt', 'w') as input_file, open('size_data.txt', 'w') as output_file:
        for i in range(group_count): 
            input_file.write(str(i) + '\n')          
            output_file.write(str(i) + "\n")
            
            random_numbers = generate_random_5bit_numbers(1)
            for number in random_numbers:
                encoded_number = hamming_encode(number)
                input_file.write(f"{encoded_number}\n")
            # 每組的未編碼數字寫入 output.txt
            for number in random_numbers:
                output_file.write(f"{number}\n")

if __name__ == "__main__":
    main()
