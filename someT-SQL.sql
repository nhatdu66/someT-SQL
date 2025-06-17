/*
/* Liệt kê schema, bảng, cột, kiểu dữ liệu, PK? (có/không)  */
SELECT  
    s.name  AS [Schema], 
    t.name  AS [Table],
    c.column_id AS [Col#],
    c.name  AS [Column],
    TYPE_NAME(c.user_type_id) 
            + COALESCE('(' + IIF(c.max_length = -1, 'MAX', 
                                 CAST(c.max_length AS varchar(10))) + ')','') 
            AS [DataType],
    CASE WHEN pk.index_id IS NULL THEN '' ELSE 'PK' END AS [Key],
    c.is_nullable AS [Nullable]
FROM        sys.tables   t
JOIN        sys.schemas  s  ON s.schema_id = t.schema_id
JOIN        sys.columns  c  ON c.object_id = t.object_id
LEFT JOIN (
        SELECT ic.object_id, ic.column_id, i.index_id
        FROM   sys.indexes        i
        JOIN   sys.index_columns  ic
               ON ic.object_id = i.object_id 
              AND ic.index_id   = i.index_id
        WHERE  i.is_primary_key = 1
) pk ON pk.object_id = c.object_id AND pk.column_id = c.column_id
ORDER BY    s.name, t.name, c.column_id;
*/

/*
/* 1. Ai đang quản lý “Phòng Nghiên cứu và phát triển” */
SELECT  e.empSSN  AS MaNhanVien,
        e.empName AS HoTen,
        d.depNum  AS MaPhong,
        d.depName AS TenPhong
FROM    dbo.tblDepartment d
JOIN    dbo.tblEmployee   e ON e.empSSN = d.mgrSSN
WHERE   d.depName = N'Phòng Nghiên cứu và phát triển';


/* 2. Phòng đó quản lý dự án nào */
SELECT  p.proNum  AS MaDuAn,
        p.proName AS TenDuAn,
        d.depName AS TenPhongQuanLy
FROM    dbo.tblDepartment d
JOIN    dbo.tblProject    p ON p.depNum = d.depNum
WHERE   d.depName = N'Phòng Nghiên cứu và phát triển';


/* 3. Dự án “ProjectB” do phòng ban nào quản lý */
SELECT  p.proNum  AS MaDuAn,
        p.proName AS TenDuAn,
        d.depName AS TenPhongQuanLy
FROM    dbo.tblProject    p
JOIN    dbo.tblDepartment d ON d.depNum = p.depNum
WHERE   p.proName = N'ProjectB';


/* 4. Nhân viên bị giám sát bởi “Mai Duy An” */
SELECT  e.empSSN  AS MaNhanVien,
        e.empName AS HoTen
FROM    dbo.tblEmployee e                -- nhân viên bị giám sát
JOIN    dbo.tblEmployee s ON e.supervisorSSN = s.empSSN  -- người giám sát
WHERE   s.empName = N'Mai Duy An';


/* 5. Ai giám sát “Mai Duy An” */
SELECT  DISTINCT
        s.empSSN  AS MaNhanVien,
        s.empName AS HoTenGiamSat
FROM    dbo.tblEmployee e                -- Mai Duy An
JOIN    dbo.tblEmployee s ON e.supervisorSSN = s.empSSN
WHERE   e.empName = N'Mai Duy An';


/* 6. Dự án “ProjectA” đang làm việc ở đâu */
SELECT  l.locNum  AS MaViTri,
        l.locName AS TenViTri
FROM    dbo.tblProject  p
JOIN    dbo.tblLocation l ON l.locNum = p.locNum
WHERE   p.proName = N'ProjectA';


/* 7. Vị trí “Tp. HCM” có những dự án nào */
SELECT  p.proNum  AS MaDuAn,
        p.proName AS TenDuAn
FROM    dbo.tblLocation l
JOIN    dbo.tblProject  p ON p.locNum = l.locNum
WHERE   l.locName = N'Tp. HCM';


/* 8. Người phụ thuộc trên 18 tuổi */
SELECT  d.depName       AS TenNguoiPhuThuoc,
        d.depBirthdate  AS NgaySinh,
        e.empName       AS TenNhanVien
FROM    dbo.tblDependent d
JOIN    dbo.tblEmployee  e ON e.empSSN = d.empSSN
WHERE   DATEDIFF(YEAR, d.depBirthdate, GETDATE()) > 18;


/* 9. Người phụ thuộc là nam giới */
SELECT  d.depName       AS TenNguoiPhuThuoc,
        d.depBirthdate  AS NgaySinh,
        e.empName       AS TenNhanVien
FROM    dbo.tblDependent d
JOIN    dbo.tblEmployee  e ON e.empSSN = d.empSSN
WHERE   d.depSex = 'M';      -- nếu bạn lưu ‘m’/’Male’ thì đổi điều kiện


/* 10. Nơi làm việc của “Phòng Nghiên cứu và phát triển” */
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong,
        l.locName AS TenNoiLamViec
FROM    dbo.tblDepartment   d
JOIN    dbo.tblDepLocation  dl ON dl.depNum = d.depNum
JOIN    dbo.tblLocation     l  ON l.locNum  = dl.locNum
WHERE   d.depName = N'Phòng Nghiên cứu và phát triển';

/* 11. Dự án làm việc tại Tp. HCM */
SELECT  p.proNum  AS MaDuAn,
        p.proName AS TenDuAn,
        d.depName AS TenPhongBan
FROM    dbo.tblProject   p
JOIN    dbo.tblLocation  l ON l.locNum = p.locNum
JOIN    dbo.tblDepartment d ON d.depNum = p.depNum
WHERE   l.locName = N'Tp. HCM';


/* 12. Người phụ thuộc NỮ của nhân viên thuộc “Phòng Nghiên cứu và phát triển” */
SELECT  e.empName AS TenNhanVien,
        dp.depName AS TenNguoiPhuThuoc,
        dp.depRelationship AS MoiLienHe
FROM    dbo.tblDependent  dp
JOIN    dbo.tblEmployee   e ON e.empSSN = dp.empSSN
JOIN    dbo.tblDepartment d ON d.depNum = e.depNum
WHERE   dp.depSex  = 'F'
  AND   d.depName  = N'Phòng Nghiên cứu và phát triển';


/* 13. Người phụ thuộc > 18 tuổi của nhân viên thuộc “Phòng Nghiên cứu và phát triển” */
SELECT  e.empName AS TenNhanVien,
        dp.depName AS TenNguoiPhuThuoc,
        dp.depRelationship AS MoiLienHe
FROM    dbo.tblDependent  dp
JOIN    dbo.tblEmployee   e ON e.empSSN = dp.empSSN
JOIN    dbo.tblDepartment d ON d.depNum = e.depNum
WHERE   DATEDIFF(YEAR, dp.depBirthdate, GETDATE()) > 18
  AND   d.depName = N'Phòng Nghiên cứu và phát triển';


/* 14. Số lượng người phụ thuộc theo giới tính */
SELECT  dp.depSex AS GioiTinh,
        COUNT(*)  AS SoLuong
FROM    dbo.tblDependent dp
GROUP BY dp.depSex;


/* 15. Số lượng người phụ thuộc theo mối liên hệ */
SELECT  dp.depRelationship AS MoiLienHe,
        COUNT(*)          AS SoLuong
FROM    dbo.tblDependent dp
GROUP BY dp.depRelationship;


/* 16. Số lượng người phụ thuộc theo phòng ban */
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong,
        COUNT(*)   AS SoLuongPhuThuoc
FROM    dbo.tblDependent  dp
JOIN    dbo.tblEmployee   e ON e.empSSN = dp.empSSN
JOIN    dbo.tblDepartment d ON d.depNum = e.depNum
GROUP BY d.depNum, d.depName;


/* 17. Phòng ban có ÍT người phụ thuộc nhất */
WITH CTE AS (
    SELECT d.depNum, d.depName, COUNT(*) AS SoLuongPhuThuoc
    FROM   dbo.tblDependent dp
    JOIN   dbo.tblEmployee  e ON e.empSSN = dp.empSSN
    JOIN   dbo.tblDepartment d ON d.depNum = e.depNum
    GROUP  BY d.depNum, d.depName
)
SELECT TOP (1) WITH TIES *
FROM   CTE
ORDER  BY SoLuongPhuThuoc ASC;


/* 18. Phòng ban có NHIỀU người phụ thuộc nhất */
WITH CTE AS (
    SELECT d.depNum, d.depName, COUNT(*) AS SoLuongPhuThuoc
    FROM   dbo.tblDependent dp
    JOIN   dbo.tblEmployee  e ON e.empSSN = dp.empSSN
    JOIN   dbo.tblDepartment d ON d.depNum = e.depNum
    GROUP  BY d.depNum, d.depName
)
SELECT TOP (1) WITH TIES *
FROM   CTE
ORDER  BY SoLuongPhuThuoc DESC;


/* 19. Tổng giờ tham gia dự án của mỗi nhân viên */
SELECT  e.empSSN  AS MaNhanVien,
        e.empName AS TenNhanVien,
        d.depName AS TenPhongBan,
        SUM(w.workHours) AS TongGio
FROM    dbo.tblWorksOn  w
JOIN    dbo.tblEmployee e ON e.empSSN = w.empSSN
JOIN    dbo.tblDepartment d ON d.depNum = e.depNum
GROUP BY e.empSSN, e.empName, d.depName;


/* 20. Tổng giờ làm dự án của mỗi phòng ban */
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong,
        SUM(w.workHours) AS TongGio
FROM    dbo.tblWorksOn  w
JOIN    dbo.tblEmployee e ON e.empSSN = w.empSSN
JOIN    dbo.tblDepartment d ON d.depNum = e.depNum
GROUP BY d.depNum, d.depName;

/*------------------------------------------------------------
21. Nhân viên có TỔNG giờ tham gia dự án ÍT NHẤT
------------------------------------------------------------*/
WITH EmpHours AS (
    SELECT  e.empSSN  AS MaNhanVien,
            e.empName AS TenNhanVien,
            SUM(w.workHours) AS TongGio
    FROM    dbo.tblEmployee e
    JOIN    dbo.tblWorksOn  w ON w.empSSN = e.empSSN
    GROUP BY e.empSSN, e.empName
)
SELECT TOP (1) WITH TIES *
FROM   EmpHours
ORDER  BY TongGio ASC;


/*------------------------------------------------------------
22. Nhân viên có TỔNG giờ tham gia dự án NHIỀU NHẤT
------------------------------------------------------------*/
WITH EmpHours AS (
    SELECT  e.empSSN  AS MaNhanVien,
            e.empName AS TenNhanVien,
            SUM(w.workHours) AS TongGio
    FROM    dbo.tblEmployee e
    JOIN    dbo.tblWorksOn  w ON w.empSSN = e.empSSN
    GROUP BY e.empSSN, e.empName
)
SELECT TOP (1) WITH TIES *
FROM   EmpHours
ORDER  BY TongGio DESC;


/*------------------------------------------------------------
23. Nhân viên LẦN ĐẦU (chỉ 1 dự án)
------------------------------------------------------------*/
WITH EmpProj AS (
    SELECT  e.empSSN, e.empName, d.depName,
            COUNT(DISTINCT w.proNum) AS SoDuAn
    FROM    dbo.tblEmployee  e
    LEFT JOIN dbo.tblWorksOn w ON w.empSSN = e.empSSN
    JOIN     dbo.tblDepartment d ON d.depNum = e.depNum
    GROUP BY e.empSSN, e.empName, d.depName
)
SELECT  empSSN  AS MaNhanVien,
        empName AS TenNhanVien,
        depName AS TenPhongBan
FROM    EmpProj
WHERE   SoDuAn = 1;


/*------------------------------------------------------------
24. Nhân viên LẦN THỨ HAI (2 dự án)
------------------------------------------------------------*/
WITH EmpProj AS (
    SELECT  e.empSSN, e.empName, d.depName,
            COUNT(DISTINCT w.proNum) AS SoDuAn
    FROM    dbo.tblEmployee  e
    LEFT JOIN dbo.tblWorksOn w ON w.empSSN = e.empSSN
    JOIN     dbo.tblDepartment d ON d.depNum = e.depNum
    GROUP BY e.empSSN, e.empName, d.depName
)
SELECT  empSSN  AS MaNhanVien,
        empName AS TenNhanVien,
        depName AS TenPhongBan
FROM    EmpProj
WHERE   SoDuAn = 2;


/*------------------------------------------------------------
25. Nhân viên tham gia TỐI THIỂU HAI dự án (≥ 2)
------------------------------------------------------------*/
WITH EmpProj AS (
    SELECT  e.empSSN, e.empName, d.depName,
            COUNT(DISTINCT w.proNum) AS SoDuAn
    FROM    dbo.tblEmployee  e
    LEFT JOIN dbo.tblWorksOn w ON w.empSSN = e.empSSN
    JOIN     dbo.tblDepartment d ON d.depNum = e.depNum
    GROUP BY e.empSSN, e.empName, d.depName
)
SELECT  empSSN  AS MaNhanVien,
        empName AS TenNhanVien,
        depName AS TenPhongBan
FROM    EmpProj
WHERE   SoDuAn >= 2;


/*------------------------------------------------------------
26. Số lượng THÀNH VIÊN của mỗi dự án
------------------------------------------------------------*/
SELECT  p.proNum  AS MaDuAn,
        p.proName AS TenDuAn,
        COUNT(DISTINCT w.empSSN) AS SoLuongThanhVien
FROM    dbo.tblProject  p
LEFT JOIN dbo.tblWorksOn w ON w.proNum = p.proNum
GROUP BY p.proNum, p.proName;


/*------------------------------------------------------------
27. TỔNG GIỜ làm của mỗi dự án
------------------------------------------------------------*/
SELECT  p.proNum  AS MaDuAn,
        p.proName AS TenDuAn,
        ISNULL(SUM(w.workHours),0) AS TongGio
FROM    dbo.tblProject  p
LEFT JOIN dbo.tblWorksOn w ON w.proNum = p.proNum
GROUP BY p.proNum, p.proName;


/*------------------------------------------------------------
28. Dự án có SỐ THÀNH VIÊN ÍT NHẤT
------------------------------------------------------------*/
WITH ProMembers AS (
    SELECT  p.proNum, p.proName,
            COUNT(DISTINCT w.empSSN) AS SoLuongThanhVien
    FROM    dbo.tblProject  p
    LEFT JOIN dbo.tblWorksOn w ON w.proNum = p.proNum
    GROUP BY p.proNum, p.proName
)
SELECT TOP (1) WITH TIES *
FROM   ProMembers
ORDER  BY SoLuongThanhVien ASC;


/*------------------------------------------------------------
29. Dự án có SỐ THÀNH VIÊN NHIỀU NHẤT
------------------------------------------------------------*/
WITH ProMembers AS (
    SELECT  p.proNum, p.proName,
            COUNT(DISTINCT w.empSSN) AS SoLuongThanhVien
    FROM    dbo.tblProject  p
    LEFT JOIN dbo.tblWorksOn w ON w.proNum = p.proNum
    GROUP BY p.proNum, p.proName
)
SELECT TOP (1) WITH TIES *
FROM   ProMembers
ORDER  BY SoLuongThanhVien DESC;


/*------------------------------------------------------------
30. Dự án có TỔNG GIỜ làm ÍT NHẤT
------------------------------------------------------------*/
WITH ProHours AS (
    SELECT  p.proNum, p.proName,
            ISNULL(SUM(w.workHours),0) AS TongGio
    FROM    dbo.tblProject  p
    LEFT JOIN dbo.tblWorksOn w ON w.proNum = p.proNum
    GROUP BY p.proNum, p.proName
)
SELECT TOP (1) WITH TIES *
FROM   ProHours
ORDER  BY TongGio ASC;


/*────────────────────────────────────────────────────────────
31.  Dự án có TỔNG GIỜ làm NHIỀU NHẤT
────────────────────────────────────────────────────────────*/
WITH ProHours AS (
    SELECT  p.proNum , p.proName ,
            ISNULL(SUM(w.workHours),0) AS TongGio
    FROM    dbo.tblProject  p
    LEFT JOIN dbo.tblWorksOn w ON w.proNum = p.proNum
    GROUP BY p.proNum, p.proName
)
SELECT TOP (1) WITH TIES *
FROM   ProHours
ORDER  BY TongGio DESC;


/*────────────────────────────────────────────────────────────
32.  Số lượng PHÒNG BAN làm việc tại mỗi NƠI LÀM VIỆC
────────────────────────────────────────────────────────────*/
SELECT  l.locName AS TenNoiLamViec,
        COUNT(DISTINCT dl.depNum) AS SoLuongPhongBan
FROM    dbo.tblLocation    l
LEFT JOIN dbo.tblDepLocation dl ON dl.locNum = l.locNum
GROUP BY l.locName;


/*────────────────────────────────────────────────────────────
33.  Số lượng CHỖ LÀM VIỆC của mỗi PHÒNG BAN
────────────────────────────────────────────────────────────*/
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong,
        COUNT(DISTINCT dl.locNum) AS SoLuongChoLamViec
FROM    dbo.tblDepartment  d
LEFT JOIN dbo.tblDepLocation dl ON dl.depNum = d.depNum
GROUP BY d.depNum, d.depName;


/*────────────────────────────────────────────────────────────
34.  Phòng ban có NHIỀU CHỖ LÀM VIỆC NHẤT
────────────────────────────────────────────────────────────*/
WITH DeptLoc AS (
    SELECT  d.depNum, d.depName,
            COUNT(DISTINCT dl.locNum) AS SoLuongCho
    FROM    dbo.tblDepartment d
    LEFT JOIN dbo.tblDepLocation dl ON dl.depNum = d.depNum
    GROUP BY d.depNum, d.depName
)
SELECT TOP (1) WITH TIES *
FROM   DeptLoc
ORDER  BY SoLuongCho DESC;


/*────────────────────────────────────────────────────────────
35.  Phòng ban có ÍT CHỖ LÀM VIỆC NHẤT
────────────────────────────────────────────────────────────*/
WITH DeptLoc AS (
    SELECT  d.depNum, d.depName,
            COUNT(DISTINCT dl.locNum) AS SoLuongCho
    FROM    dbo.tblDepartment d
    LEFT JOIN dbo.tblDepLocation dl ON dl.depNum = d.depNum
    GROUP BY d.depNum, d.depName
)
SELECT TOP (1) WITH TIES *
FROM   DeptLoc
ORDER  BY SoLuongCho ASC;


/*────────────────────────────────────────────────────────────
36.  Địa điểm có NHIỀU PHÒNG BAN làm việc nhất
────────────────────────────────────────────────────────────*/
WITH LocDept AS (
    SELECT  l.locName,
            COUNT(DISTINCT dl.depNum) AS SoLuongPhongBan
    FROM    dbo.tblLocation l
    LEFT JOIN dbo.tblDepLocation dl ON dl.locNum = l.locNum
    GROUP BY l.locName
)
SELECT TOP (1) WITH TIES *
FROM   LocDept
ORDER  BY SoLuongPhongBan DESC;


/*────────────────────────────────────────────────────────────
37.  Địa điểm có ÍT PHÒNG BAN làm việc nhất
────────────────────────────────────────────────────────────*/
WITH LocDept AS (
    SELECT  l.locName,
            COUNT(DISTINCT dl.depNum) AS SoLuongPhongBan
    FROM    dbo.tblLocation l
    LEFT JOIN dbo.tblDepLocation dl ON dl.locNum = l.locNum
    GROUP BY l.locName
)
SELECT TOP (1) WITH TIES *
FROM   LocDept
ORDER  BY SoLuongPhongBan ASC;


/*────────────────────────────────────────────────────────────
38.  Nhân viên có NHIỀU NGƯỜI PHỤ THUỘC nhất
────────────────────────────────────────────────────────────*/
WITH EmpDep AS (
    SELECT  e.empSSN, e.empName,
            COUNT(dp.depName) AS SoPhuThuoc
    FROM    dbo.tblEmployee  e
    LEFT JOIN dbo.tblDependent dp ON dp.empSSN = e.empSSN
    GROUP BY e.empSSN, e.empName
)
SELECT TOP (1) WITH TIES *
FROM   EmpDep
ORDER  BY SoPhuThuoc DESC;


/*────────────────────────────────────────────────────────────
39.  Nhân viên có ÍT NGƯỜI PHỤ THUỘC nhất (nhưng > 0)
────────────────────────────────────────────────────────────*/
WITH EmpDep AS (
    SELECT  e.empSSN, e.empName,
            COUNT(dp.depName) AS SoPhuThuoc
    FROM    dbo.tblEmployee  e
    LEFT JOIN dbo.tblDependent dp ON dp.empSSN = e.empSSN
    GROUP BY e.empSSN, e.empName
)
SELECT TOP (1) WITH TIES *
FROM   EmpDep
WHERE  SoPhuThuoc > 0
ORDER  BY SoPhuThuoc ASC;


/*────────────────────────────────────────────────────────────
40.  Nhân viên KHÔNG có người phụ thuộc
────────────────────────────────────────────────────────────*/
SELECT  e.empSSN  AS MaNhanVien,
        e.empName AS TenNhanVien,
        d.depName AS TenPhongBan
FROM    dbo.tblEmployee   e
JOIN    dbo.tblDepartment d  ON d.depNum = e.depNum
LEFT JOIN dbo.tblDependent dp ON dp.empSSN = e.empSSN
WHERE   dp.empSSN IS NULL;   -- không có bản ghi dependent


/*────────────────────────────────────────────────────────────
41.  PHÒNG BAN KHÔNG CÓ NGƯỜI PHỤ THUỘC
────────────────────────────────────────────────────────────*/
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong
FROM    dbo.tblDepartment d
LEFT JOIN dbo.tblEmployee   e  ON e.depNum = d.depNum
LEFT JOIN dbo.tblDependent  dp ON dp.empSSN = e.empSSN
GROUP BY d.depNum, d.depName
HAVING  COUNT(dp.depName) = 0;      -- hoàn toàn không có dependent


/*────────────────────────────────────────────────────────────
42.  NHÂN VIÊN CHƯA THAM GIA BẤT KỲ DỰ ÁN NÀO
────────────────────────────────────────────────────────────*/
SELECT  e.empSSN  AS MaNhanVien,
        e.empName AS TenNhanVien,
        d.depName AS TenPhongBan
FROM    dbo.tblEmployee   e
JOIN    dbo.tblDepartment d  ON d.depNum = e.depNum
LEFT JOIN dbo.tblWorksOn  w  ON w.empSSN = e.empSSN
WHERE   w.empSSN IS NULL;


/*────────────────────────────────────────────────────────────
43.  PHÒNG BAN KHÔNG CÓ NHÂN VIÊN THAM GIA DỰ ÁN NÀO
────────────────────────────────────────────────────────────*/
SELECT  d.depNum, d.depName
FROM    dbo.tblDepartment d
LEFT JOIN dbo.tblEmployee   e ON e.depNum = d.depNum
LEFT JOIN dbo.tblWorksOn    w ON w.empSSN = e.empSSN
GROUP BY d.depNum, d.depName
HAVING  COUNT(w.proNum) = 0;


/*────────────────────────────────────────────────────────────
44.  PHÒNG BAN KHÔNG CÓ NHÂN VIÊN THAM GIA “ProjectA”
────────────────────────────────────────────────────────────*/
SELECT  d.depNum, d.depName
FROM    dbo.tblDepartment d
LEFT JOIN dbo.tblEmployee   e ON e.depNum = d.depNum
LEFT JOIN dbo.tblWorksOn    w ON w.empSSN = e.empSSN
LEFT JOIN dbo.tblProject    p ON p.proNum = w.proNum
                               AND p.proName = N'ProjectA'
GROUP BY d.depNum, d.depName
HAVING  COUNT(p.proNum) = 0;


/*────────────────────────────────────────────────────────────
45.  SỐ LƯỢNG DỰ ÁN ĐƯỢC QUẢN LÝ THEO MỖI PHÒNG BAN
────────────────────────────────────────────────────────────*/
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong,
        COUNT(p.proNum) AS SoLuongDuAn
FROM    dbo.tblDepartment d
LEFT JOIN dbo.tblProject   p ON p.depNum = d.depNum
GROUP BY d.depNum, d.depName;


/*────────────────────────────────────────────────────────────
46.  PHÒNG BAN QUẢN LÝ ÍT DỰ ÁN NHẤT
────────────────────────────────────────────────────────────*/
WITH DeptProj AS (
    SELECT  d.depNum, d.depName, COUNT(p.proNum) AS SoDuAn
    FROM    dbo.tblDepartment d
    LEFT JOIN dbo.tblProject p ON p.depNum = d.depNum
    GROUP BY d.depNum, d.depName
)
SELECT TOP (1) WITH TIES *
FROM   DeptProj
ORDER  BY SoDuAn ASC;


/*────────────────────────────────────────────────────────────
47.  PHÒNG BAN QUẢN LÝ NHIỀU DỰ ÁN NHẤT
────────────────────────────────────────────────────────────*/
WITH DeptProj AS (
    SELECT  d.depNum, d.depName, COUNT(p.proNum) AS SoDuAn
    FROM    dbo.tblDepartment d
    LEFT JOIN dbo.tblProject p ON p.depNum = d.depNum
    GROUP BY d.depNum, d.depName
)
SELECT TOP (1) WITH TIES *
FROM   DeptProj
ORDER  BY SoDuAn DESC;


/*────────────────────────────────────────────────────────────
48.  PHÒNG BAN >5 NHÂN VIÊN ĐANG QUẢN LÝ DỰ ÁN GÌ
────────────────────────────────────────────────────────────*/
WITH DeptEmp AS (
    SELECT  depNum, COUNT(*) AS SoNhanVien
    FROM    dbo.tblEmployee
    GROUP BY depNum
    HAVING  COUNT(*) > 5
)
SELECT  d.depNum  AS MaPhong,
        d.depName AS TenPhong,
        de.SoNhanVien,
        p.proName AS TenDuAnQuanLy
FROM    DeptEmp      de
JOIN    dbo.tblDepartment d ON d.depNum = de.depNum
JOIN    dbo.tblProject    p ON p.depNum = d.depNum
ORDER  BY d.depNum, p.proName;


/*────────────────────────────────────────────────────────────
49.  NHÂN VIÊN Ở “Phòng nghiên cứu” KHÔNG CÓ NGƯỜI PHỤ THUỘC
────────────────────────────────────────────────────────────*/
SELECT  e.empSSN  AS MaNhanVien,
        e.empName AS TenNhanVien
FROM    dbo.tblEmployee   e
JOIN    dbo.tblDepartment d  ON d.depNum = e.depNum
LEFT JOIN dbo.tblDependent dp ON dp.empSSN = e.empSSN
WHERE   d.depName = N'Phòng nghiên cứu'
  AND   dp.empSSN IS NULL;


/*────────────────────────────────────────────────────────────
50.  TỔNG GIỜ LÀM CỦA NHÂN VIÊN KHÔNG CÓ NGƯỜI PHỤ THUỘC
────────────────────────────────────────────────────────────*/
WITH EmpNoDep AS (
    SELECT  e.empSSN, e.empName
    FROM    dbo.tblEmployee e
    LEFT JOIN dbo.tblDependent dp ON dp.empSSN = e.empSSN
    WHERE   dp.empSSN IS NULL
)
SELECT  nd.empSSN  AS MaNhanVien,
        nd.empName AS TenNhanVien,
        ISNULL(SUM(w.workHours),0) AS TongGio
FROM    EmpNoDep        nd
LEFT JOIN dbo.tblWorksOn w ON w.empSSN = nd.empSSN
GROUP BY nd.empSSN, nd.empName;


/*────────────────────────────────────────────────────────────
51.  TỔNG GIỜ LÀM CỦA NHÂN VIÊN CÓ >3 NGƯỜI PHỤ THUỘC
────────────────────────────────────────────────────────────*/
WITH DepCnt AS (               -- Đếm số phụ thuộc / nhân viên
    SELECT  empSSN,
            COUNT(*) AS SoPhuThuoc
    FROM    dbo.tblDependent
    GROUP BY empSSN
    HAVING  COUNT(*) > 3       -- “> 3 người phụ thuộc”
)
SELECT  e.empSSN      AS MaNhanVien,
        e.empName     AS TenNhanVien,
        dc.SoPhuThuoc,
        ISNULL(SUM(w.workHours),0) AS TongGio
FROM        DepCnt         dc          -- chỉ nhân viên đủ điều kiện
JOIN        dbo.tblEmployee  e ON e.empSSN = dc.empSSN
LEFT JOIN   dbo.tblWorksOn   w ON w.empSSN = e.empSSN
GROUP BY    e.empSSN, e.empName, dc.SoPhuThuoc
ORDER BY    TongGio DESC;      -- tuỳ ý sắp xếp
*/

/* 52. Tổng số giờ của tất cả nhân viên do Mai Duy An giám sát */
DECLARE @BossSSN decimal(9);

SELECT  e.empSSN      AS MaNhanVien,
        e.empName     AS TenNhanVien,
        ISNULL(SUM(w.workHours),0) AS TongGio
FROM        dbo.tblEmployee  e        -- cấp dưới
LEFT JOIN   dbo.tblWorksOn   w ON w.empSSN = e.empSSN
JOIN        dbo.tblEmployee  boss     -- cấp trên
           ON boss.empSSN = e.supervisorSSN
WHERE       boss.empName = N'Mai Duy An'
GROUP BY    e.empSSN, e.empName
ORDER BY    TongGio DESC;
