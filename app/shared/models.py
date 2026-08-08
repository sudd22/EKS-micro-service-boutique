from pydantic import BaseModel, EmailStr


class UserSignUp(BaseModel):
    email: EmailStr
    password: str
    tenant_id: str | None = "default"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class ProductCreate(BaseModel):
    name: str
    description: str
    price: float
    stock: int

class ProductResponse(BaseModel):
    id: int
    name: str
    description: str
    price: float
    stock: int

class OrderItem(BaseModel):
    product_id: int
    quantity: int

class OrderCreate(BaseModel):
    items: list[OrderItem]

class OrderResponse(BaseModel):
    id: int
    user_email: str
    total_amount: float
    status: str
    created_at: str

class PaymentProcess(BaseModel):
    order_id: int
    amount: float
    payment_method: str = "credit_card"

class PaymentResponse(BaseModel):
    transaction_id: str
    order_id: int
    status: str
    amount: float
