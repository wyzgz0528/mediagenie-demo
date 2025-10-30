"""
快速测试脚�?- 检查环境和数据库连�?"""
import os
import sys
from pathlib import Path

# 添加当前目录�?Python 路径
sys.path.insert(0, str(Path(__file__).parent))

def test_imports():
    """测试必要的包是否已安�?""
    print("=" * 60)
    print("测试 1: 检�?Python �?)
    print("=" * 60)
    
    required_packages = [
        ('fastapi', 'FastAPI'),
        ('uvicorn', 'Uvicorn'),
        ('asyncpg', 'asyncpg'),
        ('sqlalchemy', 'SQLAlchemy'),
        ('pydantic', 'Pydantic'),
        ('dotenv', 'python-dotenv'),
    ]
    
    missing_packages = []
    
    for package_name, display_name in required_packages:
        try:
            __import__(package_name)
            print(f"�?{display_name} 已安�?)
        except ImportError:
            print(f"�?{display_name} 未安�?)
            missing_packages.append(package_name)
    
    if missing_packages:
        print(f"\n⚠️  缺少以下�? {', '.join(missing_packages)}")
        print(f"请运�? pip install {' '.join(missing_packages)}")
        return False
    
    print("\n�?所有必需的包都已安装\n")
    return True


def test_env_file():
    """测试 .env 文件是否存在"""
    print("=" * 60)
    print("测试 2: 检�?.env 文件")
    print("=" * 60)
    
    env_file = Path(__file__).parent / '.env'
    
    if not env_file.exists():
        print(f"�?.env 文件不存�? {env_file}")
        return False
    
    print(f"�?.env 文件存在: {env_file}")
    
    # 加载环境变量
    from dotenv import load_dotenv
    load_dotenv(env_file)
    
    # 检查关键配�?    required_vars = [
        'DATABASE_URL',
        'AZURE_OPENAI_KEY',
        'AZURE_SPEECH_KEY',
        'AZURE_VISION_KEY',
    ]
    
    missing_vars = []
    
    for var in required_vars:
        value = os.getenv(var)
        if value:
            # 隐藏敏感信息
            if 'KEY' in var or 'SECRET' in var:
                display_value = value[:10] + '...' if len(value) > 10 else '***'
            else:
                display_value = value
            print(f"�?{var} = {display_value}")
        else:
            print(f"�?{var} 未设�?)
            missing_vars.append(var)
    
    if missing_vars:
        print(f"\n⚠️  缺少以下环境变量: {', '.join(missing_vars)}")
        return False
    
    print("\n�?所有必需的环境变量都已设置\n")
    return True


def test_database_connection():
    """测试数据库连�?""
    print("=" * 60)
    print("测试 3: 检查数据库连接")
    print("=" * 60)
    
    try:
        import asyncio
        import asyncpg
        from dotenv import load_dotenv
        
        # 加载环境变量
        load_dotenv()
        
        database_url = os.getenv('DATABASE_URL')
        
        if not database_url:
            print("�?DATABASE_URL 未设�?)
            return False
        
        # 移除 +asyncpg 后缀 (如果�?
        if '+asyncpg' in database_url:
            database_url = database_url.replace('+asyncpg', '')
        
        print(f"数据�?URL: {database_url.split('@')[0]}@***")
        
        async def check_connection():
            try:
                conn = await asyncpg.connect(database_url)
                
                # 测试查询
                version = await conn.fetchval('SELECT version()')
                print(f"�?数据库连接成�?)
                print(f"PostgreSQL 版本: {version.split(',')[0]}")
                
                await conn.close()
                return True
            
            except Exception as e:
                print(f"�?数据库连接失�? {str(e)}")
                return False
        
        result = asyncio.run(check_connection())
        
        if result:
            print("\n�?数据库连接正常\n")
        else:
            print("\n�?数据库连接失�?)
            print("提示:")
            print("1. 确保 PostgreSQL 服务正在运行")
            print("2. 检�?DATABASE_URL 配置是否正确")
            print("3. 确保数据库已创建: CREATE DATABASE mediagenie;")
        
        return result
    
    except Exception as e:
        print(f"�?测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


def test_files_exist():
    """测试必要的文件是否存�?""
    print("=" * 60)
    print("测试 4: 检查项目文�?)
    print("=" * 60)
    
    base_dir = Path(__file__).parent
    
    required_files = [
        'main.py',
        'config.py',
        'models.py',
        'database.py',
        'db_service.py',
        'marketplace.py',
        'marketplace_webhook.py',
        'saas_fulfillment_client.py',
        'auth_middleware.py',
        'run_migration.py',
        'test_db_connection.py',
        'migrations/001_marketplace_tables.sql',
    ]
    
    missing_files = []
    
    for file_path in required_files:
        full_path = base_dir / file_path
        if full_path.exists():
            print(f"�?{file_path}")
        else:
            print(f"�?{file_path} 不存�?)
            missing_files.append(file_path)
    
    if missing_files:
        print(f"\n⚠️  缺少以下文件: {', '.join(missing_files)}")
        return False
    
    print("\n�?所有必需的文件都存在\n")
    return True


def main():
    """运行所有测�?""
    print("\n" + "=" * 60)
    print("MediaGenie 环境快速测�?)
    print("=" * 60 + "\n")
    
    results = []
    
    # 测试 1: 检查包
    results.append(("包安�?, test_imports()))
    
    # 测试 2: 检�?.env 文件
    results.append((".env 文件", test_env_file()))
    
    # 测试 3: 检查文�?    results.append(("项目文件", test_files_exist()))
    
    # 测试 4: 检查数据库连接
    results.append(("数据库连�?, test_database_connection()))
    
    # 总结
    print("=" * 60)
    print("测试总结")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "�?通过" if result else "�?失败"
        print(f"{status} - {name}")
    
    print(f"\n总计: {passed}/{total} 测试通过")
    
    if passed == total:
        print("\n🎉 所有测试通过！可以继续执行数据库迁移�?)
        print("\n下一�?")
        print("  python run_migration.py")
        return 0
    else:
        print("\n⚠️  部分测试失败，请先解决上述问题�?)
        return 1


if __name__ == '__main__':
    sys.exit(main())

