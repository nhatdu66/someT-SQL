-- ================================================
-- Ví dụ tổng hợp T-SQL với các từ khóa & câu lệnh
-- Tất cả tên bảng, cột, biến đều dùng tiếng Việt:
--   ten_bang, ten_cot, ten_bien, …
-- Ghi chú (#) mô tả công dụng bên cạnh hoặc phía trên
-- ================================================

-- 1. TẠO & CHUYỂN NGỮ CẢNH DATABASE
USE master;
GO
-- Tạo một database mới tên Demo_TSQL
CREATE DATABASE Demo_TSQL;
GO
-- Chuyển sang database Demo_TSQL để thực thi các lệnh tiếp theo
USE Demo_TSQL;
GO

-- 2. TẠO SCHEMA
-- Phân nhóm đối tượng trong database
CREATE SCHEMA ViDuSchema;
GO

-- 3. TẠO BẢNG (CREATE TABLE)
-- Bảng Sinh Viên với khóa chính, IDENTITY, NOT NULL, NULL
CREATE TABLE ViDuSchema.BangSinhVien(
    MaSinhVien    INT            IDENTITY(1,1) NOT NULL,  -- Khóa chính tự tăng
    HoTen         NVARCHAR(100)  NOT NULL,                -- Bắt buộc phải có tên
    DiaChi        NVARCHAR(200)  NULL,                    -- Cho phép để trống
    GioiTinh      CHAR(1)        NULL,                    -- M / F
    CONSTRAINT PK_BangSinhVien PRIMARY KEY (MaSinhVien)
);
GO

-- Bảng Giáo Viên tương tự
CREATE TABLE ViDuSchema.BangGiaoVien(
    MaGiaoVien    INT            IDENTITY(1,1) NOT NULL,
    HoTen         NVARCHAR(100)  NULL,
    DiaChi        NVARCHAR(200)  NULL,
    GioiTinh      CHAR(1)        NULL,
    CONSTRAINT PK_BangGiaoVien PRIMARY KEY (MaGiaoVien)
);
GO

-- Bảng Lớp có FOREIGN KEY tham chiếu Giáo Viên
CREATE TABLE ViDuSchema.BangLop(
    MaLop         INT            IDENTITY(1,1) NOT NULL,
    TenLop        NVARCHAR(50)   NULL,
    SiSo          INT            NULL,
    NamHoc        INT            NULL,
    MaGiaoVienCN  INT            NULL,  -- Giáo viên chủ nhiệm
    CONSTRAINT PK_BangLop PRIMARY KEY (MaLop),
    CONSTRAINT FK_Lop_GiaoVien 
      FOREIGN KEY (MaGiaoVienCN) 
      REFERENCES ViDuSchema.BangGiaoVien(MaGiaoVien)
);
GO

-- Bảng Điểm Danh với composite PK và 2 FK
CREATE TABLE ViDuSchema.BangDiemDanh(
    MaSinhVien    INT     NOT NULL,
    MaLop         INT     NOT NULL,
    Ngay          DATE    NOT NULL,
    Tiet          INT     NOT NULL,
    DiemDanh      BIT     NULL,  -- 1=có mặt, 0=vắng
    CONSTRAINT PK_BangDiemDanh 
      PRIMARY KEY (MaSinhVien, MaLop, Ngay, Tiet),
    CONSTRAINT FK_DiemDanh_SinhVien 
      FOREIGN KEY (MaSinhVien) 
      REFERENCES ViDuSchema.BangSinhVien(MaSinhVien),
    CONSTRAINT FK_DiemDanh_Lop 
      FOREIGN KEY (MaLop) 
      REFERENCES ViDuSchema.BangLop(MaLop)
);
GO

-- 4. CHÈN DỮ LIỆU (INSERT)
-- Chèn đa dòng, không chỉ định cột => theo thứ tự định nghĩa
INSERT INTO ViDuSchema.BangSinhVien
VALUES
  (N'Nguyễn Văn A', N'Hà Nội',    N'M'),
  (N'Trần Thị B',  N'Hải Phòng',   N'F');
-- Chèn chỉ 1 cột, các cột còn lại NULL hoặc DEFAULT
INSERT INTO ViDuSchema.BangGiaoVien (HoTen)
VALUES (N'Lê Văn C');
GO

-- 5. TRUY VẤN & LỌC DỮ LIỆU
-- 5.1 Liệt kê bảng & databases
SELECT * FROM sys.databases;  -- sys.databases
SELECT * FROM sys.tables;     -- sys.tables

-- 5.2 SELECT DISTINCT
SELECT DISTINCT GioiTinh
FROM ViDuSchema.BangSinhVien;

-- 5.3 WHERE, IS NULL, IS NOT NULL
SELECT HoTen, DiaChi
FROM ViDuSchema.BangSinhVien
WHERE DiaChi IS NOT NULL
  AND HoTen <> N'';

-- 5.4 LIKE với % và _
SELECT HoTen
FROM ViDuSchema.BangSinhVien
WHERE HoTen LIKE N'N%'      -- Bắt đầu bằng N
   OR HoTen LIKE N'%a';      -- Kết thúc bằng a
SELECT HoTen
FROM ViDuSchema.BangSinhVien
WHERE HoTen LIKE N'_u%'      -- Ký tự bất kỳ + 'u' + …

-- 5.5 KẾT HỢP BẢNG (JOIN)
-- INNER JOIN: chỉ lấy có khớp
SELECT sv.HoTen   AS TenSV,
       gv.HoTen   AS TenGV
FROM ViDuSchema.BangSinhVien sv
INNER JOIN ViDuSchema.BangLop l 
  ON sv.MaSinhVien = l.MaLop      -- minh họa INNER JOIN
-- LEFT JOIN: lấy tất cả sv, ghép gv nếu có
LEFT JOIN ViDuSchema.BangGiaoVien gv 
  ON l.MaGiaoVienCN = gv.MaGiaoVien;

-- RIGHT JOIN & FULL JOIN tương tự

-- 5.6 PHÂN TÍCH NHÓM (GROUP BY, HAVING, ORDER BY)
SELECT GioiTinh,
       COUNT(*)      AS SoLuong,
       AVG(LEN(HoTen)) AS DoDaiTB
FROM ViDuSchema.BangSinhVien
GROUP BY GioiTinh
HAVING COUNT(*) > 0
ORDER BY SoLuong DESC;

-- 5.7 HÀM TỔNG HỢP: COUNT, AVG, SUM, MIN, MAX
SELECT MaLop,
       COUNT(MaSinhVien) AS TongSV,
       AVG(Tiet)         AS TB_TietPerNgay
FROM ViDuSchema.BangDiemDanh
GROUP BY MaLop;

-- 6. HÀM XỬ LÝ VĂN BẢN
SELECT 
  LEN(HoTen)           AS DoDai,
  LOWER(HoTen)         AS Thuong,
  UPPER(HoTen)         AS Hoa,
  SUBSTRING(HoTen,1,3) AS Prefix3,
  REPLACE(HoTen,N' ',N'.') AS DoiKhoangTrang
FROM ViDuSchema.BangSinhVien;

-- CONCAT & CONCAT_WS
SELECT
  CONCAT(HoTen, N' - ', DiaChi)     AS KetNoi1,
  CONCAT_WS(N'; ', HoTen, DiaChi)   AS KetNoi2
FROM ViDuSchema.BangSinhVien;

-- 7. HÀM SỐ HỌC & TOÁN TỬ
SELECT
  60*60*24*7         AS SoGiayTuan,
  25/4               AS PhepChiaNguyen,        -- kết quả INT
  25.0/4             AS PhepChiaThapPhan,      -- kết quả DECIMAL
  13 % 2             AS PhanDu,                -- MOD operator
  ROUND(1234.56789,3)AS LamTron3,
  CEILING(13.1)      AS LamTronLen,            
  FLOOR(13.8)        AS LamTronXuong;

-- ÉP KIỂU để tránh chia nguyên
SELECT CAST(25 AS DECIMAL(10,2))/4 AS ChiaChinhXac;

-- 8. HÀM XỬ LÝ NULL
SELECT HoTen
FROM ViDuSchema.BangSinhVien
WHERE DiaChi IS NOT NULL;

SELECT
  HoTen,
  ISNULL(DiaChi, N'Chưa có địa chỉ')   AS DiaChi_ISNULL,
  COALESCE(DiaChi, N'Chưa có địa chỉ') AS DiaChi_COALESCE
FROM ViDuSchema.BangSinhVien;

-- NULLIF: tránh chia cho 0
DECLARE @a INT = 0, @b INT = 100;
SELECT @b / NULLIF(@a,0) AS KetQuaChia;  -- NULL nếu @a=0

-- 9. ALTER TABLE (THAY ĐỔI BẢNG)
-- Thêm cột Email
ALTER TABLE ViDuSchema.BangSinhVien
  ADD Email NVARCHAR(100) NULL;
GO
-- Đổi kiểu cột HoTen
ALTER TABLE ViDuSchema.BangSinhVien
  ALTER COLUMN HoTen NVARCHAR(200) NOT NULL;
GO
-- Xóa cột Email
ALTER TABLE ViDuSchema.BangSinhVien
  DROP COLUMN Email;
GO

-- 10. ĐỔI TÊN (sp_rename)
-- Đổi tên bảng và cột
EXEC sp_rename 'ViDuSchema.BangSinhVien','SV';
GO
EXEC sp_rename 'ViDuSchema.SV.HoTen','TenNguoi','COLUMN';
GO

-- 11. XÓA BẢNG & DATABASE
-- DROP TABLE ViDuSchema.SV;
-- DROP DATABASE Demo_TSQL;

-- 12. STORED PROCEDURE & EXECUTE
CREATE PROCEDURE ViDuSchema.TinhSoSVTheoLop
  @MaLop       INT,
  @KetQua      INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;  
  SELECT @KetQua = COUNT(*)
  FROM ViDuSchema.BangSinhVien
  WHERE MaLop = @MaLop;

  IF @KetQua IS NULL
    SET @KetQua = 0;
END;
GO

-- Gọi procedure và lấy kết quả qua biến OUTPUT
DECLARE @SoSV INT;
EXEC ViDuSchema.TinhSoSVTheoLop 
  @MaLop = 1, 
  @KetQua = @SoSV OUTPUT;
SELECT @SoSV AS TongSV;

-- 13. TRIGGER & inserted
CREATE TRIGGER ViDuSchema.TRG_SauKhiDiemDanh
  ON ViDuSchema.BangDiemDanh
  AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  -- Bảng ảo inserted chứa các bản ghi mới
  SELECT i.MaSinhVien, i.Ngay, i.Tiet, sv.HoTen
  FROM inserted i
  INNER JOIN ViDuSchema.BangSinhVien sv
    ON i.MaSinhVien = sv.MaSinhVien;
END;
GO

-- 14. SCOPE_IDENTITY() & TRANSACTION DEMO
-- Ví dụ lấy giá trị IDENTITY vừa sinh
INSERT INTO ViDuSchema.BangGiaoVien (HoTen)
VALUES (N'Phùng Văn Xinh');
DECLARE @IDMoi INT = SCOPE_IDENTITY();
SELECT @IDMoi AS MaGiaoVienMoi;
